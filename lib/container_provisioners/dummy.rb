require_relative 'base'

module Rook
  class DummyContainerProvisioner < BaseContainerProvisioner
    def provision(host, component)
      container = Container.new
      container.id = rand(0xFFFF)
      logger.info "Provisioned dummy container #{container.id} on host #{host.address}!"
      container
    end

    def deprovision(containers)
      containers = [containers].flatten
      containers.each do |container|
        logger.info "Deprovision dummy container #{container.id}!"
      end
    end
  end
end
