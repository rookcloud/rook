require_relative '../constants'
require_relative '../safe_yaml'
require_relative 'hash_utils'

module Rook
  module Config
    class Component
      attr_accessor :config, :instances
      attr_accessor(*COMPONENT_COMMON_ATTRIBUTES)

      alias uses_master_slave_replication? uses_master_slave_replication

      def self.from_yaml(config, yaml)
        component = new(config)
        component.instances = HASH_UTILS.get_int(yaml, 'instances', 1)
        component.type      = HASH_UTILS.get_str!(yaml, 'type')
        component.repo_url  = HASH_UTILS.get_str!(yaml, 'repo_url')
        component.repo_type = HASH_UTILS.get_str(yaml, 'repo_type', 'git')
        component
      end

      def initialize(config)
        @config    = config
        @instances = 0
      end

      def load_attributes_from_rookdir
        manifest = ::File.join(@config.rookdir, type, "rook-component.yml")
        if !::File.exist?(manifest)
          raise ConfigFileLoadError, "Cannot find file #{manifest}. It appears that the " +
            "'#{type}' component is corrupted. Please reinstall this component with: rook add -f #{type}"
        end
        yaml = YAML.load_file(manifest)

        self.version      = HASH_UTILS.get_str!(yaml, 'version')
        self.docker_image = HASH_UTILS.get_str(yaml, 'docker_image', "rook/#{type}")
        self.uses_master_slave_replication = HASH_UTILS.get_bool(yaml,
          'uses_master_slave_replication')
      end

      def copy_attributes_from_state_component(sc)
        COMPONENT_COMMON_ATTRIBUTES.each do |attr|
          send("#{attr}=", sc.send(attr))
        end
      end
    end
  end
end
