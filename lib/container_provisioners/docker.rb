require 'shellwords'
require_relative 'base'

module Rook
  class DockerProvisioner < BaseContainerProvisioner
    def provision(host, component)
      command = "docker pull #{shq component.docker_image}"
      raise "TODO"
      ssh_run(host, command)
    end

    def deprovision(containers)
      containers = [containers].flatten
      containers.each do |container|
        command = "docker stop #{shq container.id}; docker rm #{shq container.id}"
        ssh_run(container.host, command)
      end
    end

  private
    def ssh_run(host, command)
      system("ssh", "-p", host.ssh_port, host.address, command)
    end

    def shq(value)
      Shellwords.escape(value)
    end
  end
end
