require 'shellwords'
require 'erb'
require_relative 'base'

module Rook
  class DockerProvisioner < BaseContainerProvisioner
    DIR = File.absolute_path(File.dirname(__FILE__))

    def provision(host, component)
      preamble = render_template("preamble.sh.erb", binding)
      command = preamble + "\n" + File.read("#{DIR}/docker/provision.sh")
      ssh_run(host, command)

      container = Container.new
      container.id = rand(0xFFFF)
      container
    end

    def deprovision(containers)
      containers = [containers].flatten
      containers.each do |container|
        remove_container(container.host, container.id)
      end
    end

  private
    def remove_container(host, container_id)
      command = "docker stop #{shq container_id}; docker rm #{shq container_id}"
      ssh_run(container.host, command)
    end

    def render_template(name, binding)
      ERB.new(File.read("#{DIR}/docker/#{name}")).result(binding)
    end

    def ssh_run(host, command)
      logger.debug("Running on #{host}: #{command}")
      if !options[:dry_run]
        system("ssh", "-p", host.ssh_port, host.address, "exec /bin/bash -c #{shq command}")
      end
    end

    def shq(value)
      Shellwords.escape(value)
    end
  end
end
