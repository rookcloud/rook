require_relative 'base'

module Rook
  class DummyHostProvisioner < BaseHostProvisioner
    def provision(component, count)
      hosts = []
      count.times do
        number = rand(0xFFFF)
        host = Host.new
        host.name = "#{component.type} server #{number}"
        host.address = "#{number}.dummy.org"
        hosts << host
        logger.info "Provisioned dummy server #{host.name} at #{host.address}!"
      end
      hosts
    end

    def deprovision(hosts)
      hosts = [hosts].flatten
      logger.info "Deprovisioned dummy hosts #{hosts.map{ |h| h.name }.inspect}!"
    end
  end
end
