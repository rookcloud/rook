require_relative '../constants'
require_relative 'hash_utils'
require_relative 'container'

module Rook
  module State
    class Component
      attr_accessor :state, :revision, :containers
      attr_accessor(*COMPONENT_COMMON_ATTRIBUTES)

      alias consumes_services? consumes_services
      alias app_server? app_server
      alias uses_master_slave_replication? uses_master_slave_replication

      def self.from_yaml(state, yaml, all_hosts)
        component = new(state)
        component.type         = HASH_UTILS.get_str!(yaml, 'type')
        component.docker_image = HASH_UTILS.get_str!(yaml, 'docker_image')
        component.consumes_services = HASH_UTILS.get_bool(yaml, 'consumes_services')
        component.service_ports     = HASH_UTILS.get_int_array(yaml, 'service_ports')
        component.app_server   = HASH_UTILS.get_bool(yaml, 'app_server')
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

      def copy_attributes_from_config_component(cc)
        COMPONENT_COMMON_ATTRIBUTES.each do |attr|
          send("#{attr}=", cc.send(attr))
        end
      end

      def as_yaml
        result = {
          'type'         => @type,
          'docker_image' => @docker_image,
          'consumes_services' => consumes_services?,
          'app_server'        => app_server?,
          'uses_master_slave_replication' => uses_master_slave_replication?
        }
        if !@service_ports.empty?
          result['service_ports'] = @service_ports
        end
        result['containers'] = @containers.map { |c| c.as_yaml }
        result
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
