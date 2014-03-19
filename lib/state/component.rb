require_relative '../constants'
require_relative 'hash_utils'
require_relative 'container'

module Rook
  module State
    class Component
      attr_accessor :state, :revision, :containers
      attr_accessor(*COMPONENT_COMMON_ATTRIBUTES)

      alias uses_master_slave_replication? uses_master_slave_replication

      def self.from_yaml(state, yaml, all_hosts)
        component = new(state)
        component.type         = HASH_UTILS.get_str!(yaml, 'type')
        component.repo_url     = HASH_UTILS.get_str!(yaml, 'repo_url')
        component.repo_type    = HASH_UTILS.get_str!(yaml, 'repo_type')
        component.revision     = HASH_UTILS.get_str!(yaml, 'revision')
        component.version      = HASH_UTILS.get_str!(yaml, 'version')
        component.docker_image = HASH_UTILS.get_str!(yaml, 'docker_image')
        component.uses_master_slave_replication = HASH_UTILS.get_bool(yaml,
          'uses_master_slave_replication')
        component.containers   = load_containers_from_yaml(yaml, all_hosts)
        component
      end

      def initialize(state)
        @state      = state
        @containers = []
      end

      def instances
        @containers.size
      end

      def attributes_match_config_component?(cc)
        COMPONENT_COMMON_ATTRIBUTES.all? do |attr|
          send(attr) == cc.send(attr)
        end
      end

      def as_yaml
        {
          'type'         => @type,
          'repo_url'     => @repo_url,
          'repo_type'    => @repo_type,
          'revision'     => @revision,
          'docker_image' => @docker_image,
          'uses_master_slave_replication' => uses_master_slave_replication?,
          'containers'   => @containers.map { |c| c.as_yaml }
        }
      end

    private
      def self.load_containers_from_yaml(yaml, all_hosts)
        HASH_UTILS.get(yaml, 'containers', []).map do |ycontainer|
          Container.from_yaml(ycontainer, all_hosts)
        end
      end
    end
  end
end
