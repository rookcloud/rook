require_relative 'hash_utils'

module Rook
  module Config
    class Component
      attr_accessor :config, :instances, :type, :repo_url, :repo_type, :revision, :docker_image,
        :uses_master_slave_replication

      alias uses_master_slave_replication? uses_master_slave_replication

      def self.from_yaml(config, yaml)
        component = new(config)
        component.instances    = HASH_UTILS.get_int(yaml, 'instances', 1)
        component.type         = HASH_UTILS.get_str!(yaml, 'type')
        component.repo_url     = HASH_UTILS.get_str!(yaml, 'repo_url')
        component.repo_type    = HASH_UTILS.get_str!(yaml, 'repo_type')
        component.revision     = HASH_UTILS.get_str!(yaml, 'revision')
        component.docker_image = HASH_UTILS.get_str!(yaml, 'docker_image')
        component.uses_master_slave_replication = HASH_UTILS.get_bool(yaml,
          'uses_master_slave_replication')
        component
      end

      def initialize(state)
        @state = state
        @instances = 0
      end

      def copy_attributes_from_state_component(sc)
        raise "TODO"
      end
    end
  end
end
