require_relative 'hash_utils'

module Rook
  module Config
    class Host
      attr_accessor :name, :address, :ssh_port

      def self.from_yaml(yaml)
        host = new
        host.name     = HASH_UTILS.get_str!(yaml, 'name')
        host.address  = HASH_UTILS.get_str!(yaml, 'address')
        host.ssh_port = HASH_UTILS.get_str(yaml, 'ssh_port', SSH_DEFAULT_PORT)
        host
      end

      def initialize
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

      def to_s
        @name || address_and_port
      end
    end
  end
end
