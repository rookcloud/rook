require 'shellwords'
require 'erb'
require 'tmpdir'
require 'fileutils'
require_relative 'base'

module Rook
  class DockerProvisioner < BaseContainerProvisioner
    DIR = File.absolute_path(File.dirname(__FILE__))

    def create(host, component)
      if component.app_server?
        update_code(host, component)
      end

      container_id = add_container(host, component)

      container = State::Container.new
      container.id = container_id
      container
    end

    def update_code(host, component)
      if development_mode?
        update_code_in_development(component)
      else
        update_code_in_production(host, component)
      end
    end

    def destroy(containers)
      containers = [containers].flatten
      containers.each do |container|
        remove_container(container.host, container.id)
      end
    end

  private
    def add_container(host, component)
      command = "mktemp -d /tmp/rook-provision.XXXXXXXX"
      if development_mode?
        if using_vagrant?
          result_dir = vagrant_ssh_capture_first_line(component.config.rookdir, command)
        else
          result_dir = Dir.mktmpdir("rook-provision")
        end
      else
        result_dir = ssh_capture(host, command).strip
      end

      begin
        preamble = render_template("preamble.sh.erb", binding)
        command = preamble + "\n" + File.read("#{DIR}/docker/provision.sh")
        result_command = "cat #{shq result_dir}/result"

        if development_mode?
          if using_vagrant?
            vagrant_ssh_run(component.config.rookdir, command)
            result = vagrant_ssh_capture_first_line(component.config.rookdir, result_command)
          else
            sudo_run(command)
            result = File.read("#{result_dir}/result").strip
          end
        else
          ssh_run(host, command)
          result = ssh_capture(host, result_command).strip
        end
      ensure
        command = "rm -rf #{shq result_dir}"
        if development_mode?
          if using_vagrant?
            vagrant_ssh_run(component.config.rookdir, command)
          else
            FileUtils.remove_entry_secure(result_dir)
          end
        else
          ssh_run(host, command)
        end
      end

      result
    end

    def remove_container(host, container_id)
      command = "docker stop #{shq container_id}; docker rm #{shq container_id}"
      ssh_run(container.host, command)
    end

    def update_code_in_development(component)
      if using_vagrant?
        app_path = "/vagrant"
      else
        app_path = @app_path
      end
      command = %Q{
        set -e
        app_path=#{shq app_path}
        deployment_path=#{shq deployment_path}/#{shq component.type}

        mkdir -p "$deployment_path"
        rm -rf "$deployment_path/code"
        ln -s "$app_path" "$deployment_path/code"
      }
      if using_vagrant?
        vagrant_ssh_run(component.config.rookdir, command)
      else
        logger.info("Setting up local development environment.")
        sudo_run(command)
      end
    end

    def update_code_in_production(host, component)
      package_path = package_code
      begin
        upload_path = ssh_capture(host, "mktemp -d /tmp/rook-upload.XXXXXXXX").strip
        scp(package_path, host, "#{upload_path}/code.tar.gz")
        File.unlink(package_path)
        package_path = nil
        ssh_run(host, %Q{
          set -e
          upload_path=#{shq upload_path}
          deployment_path=#{shq deployment_path}/#{shq component.type}

          mkdir -p "$deployment_path"
          new_dir=`mktemp -d "$deployment_path/new.XXXXXX"`
          chmod 755 "$new_dir"
          cd "$new_dir"
          tar xzf "$upload_path/code.tar.gz"
          rm "$upload_path/code.tar.gz"
          cd ..
          rm -rf "$deployment_path/old_code
          mv "$deployment_path/code" "$deployment_path/old_code"
          mv "$new_dir" "$deployment_path/code"
          rm -rf "$deployment_path/old_code
          rm -rf "$upload_path"
        })
      ensure
        File.unlink(package_path) if package_path
      end
    end

    def render_template(name, binding)
      ERB.new(File.read("#{DIR}/docker/#{name}")).result(binding)
    end

    def package_code
      dir = Dir.mktmpdir("rook")
      system("git archive --format tar HEAD | gzip --best > #{shq dir}/code.tar.gz")
    end

    def deployment_path
      "/rook"
    end

    def ssh_run(host, command)
      logger.debug("Running on #{host}: #{command}")
      system("ssh", "-p", host.ssh_port.to_s, host.address, "exec /bin/bash -c #{shq command}")
    end

    def ssh_capture(host, command)
      logger.debug("Running on #{host}: #{command}")
      ssh_param = "exec /bin/bash -c #{shq command}"
      `ssh -p #{shq host.ssh_port} root@#{shq host.address} #{shq ssh_param}`
    end

    def scp(filename, host, host_path)
      logger.debug("Uploading #{filename} to #{host.address}:#{host_path}")
      system("scp", "-P", host.ssh_port, "root@#{host.address}:#{host_path}")
    end

    def vagrant_ssh_run(rookdir, command)
      logger.debug("Running inside Vagrant VM: #{command}")
      system("vagrant", "ssh", "-c", "sudo bash -c #{shq command}", :chdir => rookdir)
    end

    def vagrant_ssh_capture_first_line(rookdir, command)
      # 'vagrant ssh' prints "Connection to xxx closed." at termination,
      # but we're only interested in the first line anyway.
      logger.debug("Running inside Vagrant VM: #{command}")
      vagrant_param = "sudo bash -c #{shq command}"
      result = `cd #{shq rookdir} && exec vagrant ssh -c #{shq vagrant_param}`
      result.split("\n").first.strip
    end

    def sudo_run(command)
      logger.debug("Running on localhost with sudo: #{command}")
      system("sudo", "-p", "sudo password: ", "/bin/bash", "-c", command)
    end

    def shq(value)
      Shellwords.escape(value)
    end
  end
end
