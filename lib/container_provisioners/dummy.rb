require_relative 'base'

module Rook
  class DummyContainerProvisioner < BaseContainerProvisioner
    def create(host, component)
      if component.app_server?
        update_code(host, component)
      end

      container = State::Container.new
      container.id = rand(0xFFFF)
      logger.info "Provisioned dummy container #{container.id} on host #{host}!"
      container
    end

    def update_code(host, component)
      logger.info "Updated code on #{host}!"
    end

    def destroy(containers)
      containers = [containers].flatten
      containers.each do |container|
        logger.info "Deprovision dummy container #{container.id}!"
      end
    end
  end
end
