require_relative 'hash_utils'

module Rook
  module State
    class Host
      attr_accessor :name, :address, :ssh_port, :containers

      def self.from_yaml(yaml)
        host = new
        host.name     = HASH_UTILS.get_str!(yaml, 'name')
        host.address  = HASH_UTILS.get_str!(yaml, 'address')
        host.ssh_port = HASH_UTILS.get_str(yaml, 'ssh_port', SSH_DEFAULT_PORT)
        host
      end

      def initialize
        @containers = []
        @ssh_port = SSH_DEFAULT_PORT
      end

      def equivalent?(other)
        @address.downcase == other.address.downcase &&
          @ssh_port == other.ssh_port
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
          'containers' => @containers.size
        }
        result['ssh_port'] = @ssh_port if @ssh_port != SSH_DEFAULT_PORT
        result
      end

      def to_s
        @name || address_and_port
      end
    end
  end
end
