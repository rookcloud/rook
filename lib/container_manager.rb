require 'tmpdir'
require 'shellwords'

module Rook
  class ContainerManager
    def initialize(config, component, container)
      @config    = config
      @component = component
      @container = container
    end

    def install
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      if @config.development_mode?
        params << "-e"
      end
      if @component.app_server?
        params << "-a"
        if @config.development_mode?
          params << "-p"
          if @config.use_vagrant?
            params << "/vagrant"
          else
            params << @config.app_path
          end
        end
      end

      add_payload = lambda do |package_path|
        package_component_config_files(package_path)
        if @component.app_server? && !@config.development_mode?
          package_app(package_path)
        end
      end

      run_script("install.sh", params, add_payload)
    end

    def uninstall
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      run_script("uninstall.sh", params)
    end

    def start
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      if @component.app_server?
        params << "-a"
      end
      run_script("start.sh", params)
    end

    def stop
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      run_script("stop.sh", params)
    end

  private
    def run_script(name, params, add_payload = nil)
      Dir.mktmpdir do |tmpdir|
        package_path = File.join(tmpdir, "package.tar.gz")
        package_scripts(package_path)
        if add_payload
          add_payload.call(package_path)
        end

        if !@config.development_mode? || @config.use_vagrant?
          temp_dir = ssh_capture_first_line("mktemp -d /tmp/rook.XXXXXXXX")
          begin
            scp(package_path, File.join(temp_dir, "package.tar.gz"))
            ssh_run("cd #{shq temp_dir} && " +
              "tar xzf package.tar.gz && " +
              "rm package.tar.gz && " +
              "exec /bin/bash install.sh #{shqa params}")
          ensure
            ssh_run("rm -rf #{shq temp_dir}")
          end
        else
          # Running locally in development, without Vagrant.
          sh("tar", "xzf", package_path, :chdir => tmpdir)
          File.unlink(package_path)
          sudo_run(File.join(tmpdir, name))
        end
      end
    end

    def package_scripts(package_path)
      sh(tar_env, "tar czf #{shq package_path} *",
        :chdir => File.join(DIR, "container_provisioners", "docker")
    end

    def package_component_config_files(main_package_path)
      Dir.mktmpdir do |tmpdir|
        sub_package_path = File.join(tmpdir, "config.tar")

        config_component = @config.find_component(@component.type)
        sh(tar_env, "tar rf #{shq sub_package_path} .",
          :chdir => config_component.config_path)

        package_docker_options_file(sub_package_path, tmpdir)
        package_routes_file(sub_package_path, tmpdir)

        add_file_to_package(main_package_path, tmpdir, "config.tar")
      end
    end

    def package_docker_options_file(package_path, tmpdir)
      docker_options = []
      @container.service_port_redirections.each_pair do |service_port, host_port|
        docker_options << "-p 0.0.0.0:#{host_port}:#{service_port}"
      end
      @container.routes.each do |route|
        docker_options << "-e #{route.environment_name}=#{route.source_port}"
      end
      if @config.development_mode?
        docker_options << "-e ROOK_DEVELOPMENT_MODE=true"
      end
      
      File.open(File.join(tmpdir, "rook_docker_options"), "w") do |f|
        f.chmod(644)
        f.write(docker_options.join("\n"))
      end
      add_file_to_package(package_path, tmpdir, "rook_docker_options")
    end

    def package_routes_file(package_path, tmpdir)
      routes = []
      @container.routes.each do |route|
        routes << [route.source_port,
          route.destination.host.address,
          route.destination.host.ssh_port,
          route.destination.service_port_redirections[route.service_port]
        ].join(" ")
      end

      File.open(File.join(tmpdir, "rook_routes"), "w") do |f|
        f.chmod(644)
        # No trailing newline, to make bash parsing easier.
        f.write(routes.join("\n"))
      end
      add_file_to_package(package_path, tmpdir, "rook_routes")
    end

    def package_app
    end

    def add_file_to_package(package_path, dir, name)
      if package_path =~ /\.gz$/
        sh(tar_env, "tar", "rzf", package_path, name, :chdir => dir)
      else
        sh("tar", "rf", package_path, name, :chdir => dir)
      end
    end

    def host
      @container.host
    end

    def ssh_run(command)
      if @config.use_vagrant?
        logger.debug("Running inside Vagrant VM: #{command}")
        sh("vagrant", "ssh", "-c", "sudo /bin/bash -c #{shq command}", :chdir => rookdir)
      else
        logger.debug("Running on #{host}: #{command}")
        sh("ssh",
          "-p", host.ssh_port.to_s,
          "root@#{host.address}",
          "exec /bin/bash -c #{shq command}")
      end
    end

    def ssh_capture_first_line(command)
      if @config.use_vagrant?
        # 'vagrant ssh' prints "Connection to xxx closed." at termination,
        # but we're only interested in the first line anyway.
        logger.debug("Running inside Vagrant VM: #{command}")
        vagrant_param = "sudo /bin/bash -c #{shq command}"
        output = `cd #{shq rookdir} && exec vagrant ssh -c #{shq vagrant_param}`
      else
        logger.debug("Running on #{host}: #{command}")
        ssh_param = "exec /bin/bash -c #{shq command}"
        output = `ssh -p #{shq host.ssh_port} root@#{shq host.address} #{shq ssh_param}`
        if $?.exitstatus != 0
          raise "Could not run command on #{host}: #{command}"
        end
      end
      output.split("\n").first
    end

    def scp(local_path, remote_path)
      if @config.use_vagrant?
        logger.debug("Uploading #{local_path} to #{remote_path} inside the Vagrant VM")
        raise "TODO"
      else
        logger.debug("Uploading #{local_path} to #{host.address}:#{remote_path}")
        sh("scp", "-P", host.ssh_port, "root@#{host.address}:#{remote_path}")
      end
    end

    def sudo_run(command)
      logger.debug("Running on localhost with sudo: #{command}")
      system("sudo", "-p", "sudo password: ", "/bin/bash", "-c", command)
    end

    def tar_env
      { "GZIP" => "--best" }
    end

    def sh(*args)
      the_args = args.dup
      the_args.shift if the_args.first.is_a?(Hash)
      the_args.pop if the_args.last.is_a?(Hash)
      logger.debug "Running: #{the_args.join(' ')}"
      if !system(*args)
        raise "Command failed: #{the_args.join(' ')}"
      end
    end

    def shq(value)
      Shellwords.escape(value)
    end

    def shqa(ary)
      Shellwords.join(ary)
    end
  end
end
