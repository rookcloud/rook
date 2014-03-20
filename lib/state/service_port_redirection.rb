require_relative 'hash_utils'

module Rook
  module State
    # Represents the redirection of a port on a host, to a port in a container, in the same host.
    class ServicePortRedirection
      attr_accessor :host_port
      attr_accessor :container
      attr_accessor :service_port

      def self.from_yaml(yaml)
        redirection = new
        # Will be changed into a Container object by File#associate_host_service_port_redirection_containers.
        redirection.container    = HASH_UTILS.get_str!(yaml, 'container')
        redirection.service_port = HASH_UTILS.get_int!(yaml, 'service_port')
        redirection
      end

      def as_yaml
        {
          'container'    => @container.id,
          'service_port' => @service_port
        }
      end
    end
  end
end