require_relative 'constants'
require_relative 'hash_utils'

module Rook
  class Container
    attr_accessor :id, :host

    def self.from_yaml(yaml, all_hosts)
      host_name = HashUtils.get_str!(yaml, 'host')
      container = new
      container.id   = HashUtils.get_str!(yaml, 'id')
      container.host = all_hosts.find { |h| h.name == host_name }
      if container.host.nil?
        raise ConfigError, "Host #{host_name.inspect} not found in the state file's hosts list"
      end
      container.host.containers << container
      container
    end

    def as_state_yaml
      {
        'id'   => @id,
        'host' => @host.name
      }
    end
  end
end
