require_relative 'hash_utils'

module Rook
  class Host
    attr_accessor :name, :address, :ssh_port, :containers

    def self.from_yaml(yaml)
      host = new
      host.name     = HashUtils.get_str!(yaml, 'name')
      host.address  = HashUtils.get_str!(yaml, 'address')
      host.ssh_port = HashUtils.get_str(yaml, 'ssh_port', 22)
      host
    end

    def initialize
      @containers = []
      @ssh_port = 22
    end

    def equivalent?(other)
      @address.downcase == other.address.downcase &&
        @ssh_port == other.ssh_port
    end

    def as_state_yaml
      result = {
        'name' => @name,
        'address' => @address,
        'containers' => @containers.size
      }
      result['ssh_port'] = @ssh_port if @ssh_port != 22
      result
    end
  end
end
