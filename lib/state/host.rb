require_relative 'service_port_redirection'
require_relative 'hash_utils'

module Rook
  module State
    class Host
      attr_accessor :name, :address, :ssh_port, :service_port_redirections, :containers
      attr_accessor :planned_action

      def self.from_yaml(yaml)
        host = new
        host.name     = HASH_UTILS.get_str!(yaml, 'name')
        host.address  = HASH_UTILS.get_str!(yaml, 'address')
        host.ssh_port = HASH_UTILS.get_str(yaml, 'ssh_port', SSH_DEFAULT_PORT)
        host.service_port_redirections = host.send(:load_service_port_redirections, yaml)
        host
      end

      def initialize
        @containers = []
        @ssh_port = SSH_DEFAULT_PORT
        @service_port_redirections = {}
      end

      def equivalent?(other)
        @address.downcase == other.address.downcase &&
          @ssh_port == other.ssh_port
      end

      def service_redirection_port_used?(host_port)
        @service_port_redirections
      end

      def address_and_port
        if @ssh_port == SSH_DEFAULT_PORT
          @address
        else
          "#{@address}:#{@ssh_port}"
        end
      end

      def as_yaml
        result = {
          'name'       => @name,
          'address'    => @address,
          'containers' => @containers.size,
          'ssh_port'   => @ssh_port
        }
        if !@service_port_redirections.empty?
          result['service_port_redirections'] = service_port_redirections_as_yaml
        end
        result
      end

      def to_s
        @name || address_and_port
      end

    private
      def load_service_port_redirections(yaml)
        if yaml.nil? || yaml['service_port_redirections'].nil?
          {}
        else
          result = {}
          yaml['service_port_redirections'].each_pair do |host_port, yredirection|
            redirection = ServicePortRedirection.from_yaml(yredirection)
            redirection.host_port = host_port
            result[host_port] = redirection
          end
          result
        end
      end

      def service_port_redirections_as_yaml
        result = {}
        @service_port_redirections.each_pair do |host_port, redirection|
          result[host_port] = redirection.as_yaml
        end
        result
      end
    end
  end
end
