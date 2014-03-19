require_relative 'base'

module Rook
  class DummyHostProvisioner < BaseHostProvisioner
    def provision(component, count)
      hosts = []
      count.times do
        number = rand(0xFFFF)
        host = State::Host.new
        host.name = "#{component.type} host ##{number}"
        host.address = "#{number}.dummy.org"
        hosts << host
        logger.info "Provisioned dummy host: #{host}"
      end
      hosts
    end

    def deprovision(hosts)
      hosts = [hosts].flatten
      logger.info "Deprovisioned dummy hosts: #{hosts.map{ |h| h.to_s }.inspect}"
    end
  end
end
