require_relative 'base'

module Rook
  class AwsProvisioner < BaseHostProvisioner
    def provision(component, count)
      raise "TODO"
    end

    def deprovision(hosts)
      hosts = [hosts].flatten
      raise "TODO"
    end
  end
end
