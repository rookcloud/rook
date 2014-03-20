require_relative '../constants'
require_relative '../safe_yaml'
require_relative 'hash_utils'

module Rook
  module Config
    class Component
      attr_accessor :config, :instances
      attr_accessor(*COMPONENT_COMMON_ATTRIBUTES)

      alias app_server? app_server
      alias uses_master_slave_replication? uses_master_slave_replication

      def self.from_yaml(config, yaml)
        component = new(config)
        component.instances    = HASH_UTILS.get_int(yaml, 'instances', 1)
        component.type         = HASH_UTILS.get_str!(yaml, 'type')
        component.docker_image = HASH_UTILS.get_str(yaml, 'docker_image', "rook/#{component.type}")
        component.app_server   = HASH_UTILS.get_bool(yaml, 'app_server')
        component.uses_master_slave_replication = HASH_UTILS.get_bool(yaml,
          'uses_master_slave_replication')
        component
      end

      def initialize(config)
        @config    = config
        @instances = 0
      end

      def copy_attributes_from_state_component(sc)
        COMPONENT_COMMON_ATTRIBUTES.each do |attr|
          send("#{attr}=", sc.send(attr))
        end
      end
    end
  end
end
