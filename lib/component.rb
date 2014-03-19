require_relative 'hash_utils'
require_relative 'container'

module Rook
  class Component
    attr_accessor :config, :type
    # Desired number of instances. May not match the actually provisioned containers.
    attr_accessor :instances
    # The actually provisioned containers.
    attr_accessor :containers

    def self.from_yaml(config, ycomponent, ycomponent_state, all_hosts)
      component = new(config)
      component.type       = HashUtils.get_str!(ycomponent, 'type')
      component.instances  = HashUtils.get_int(ycomponent, 'instances', 1)
      component.containers = load_containers_from_yaml(ycomponent_state, all_hosts)
      component
    end

    def initialize(config)
      @config     = config
      @instances  = 0
      @containers = []
    end

    def register_containers(containers)
      @containers.concat(containers)
    end

    def unregister_containers(containers)
      containers.each do |container|
        @containers.delete(container)
      end
    end

    def uses_master_slave_replication?
      # TODO
      @type =~ /mysql/
    end

    def as_state_yaml
      {
        'type' => @type,
        'containers' => @containers.map { |c| c.as_state_yaml }
      }
    end

  private
    def self.load_containers_from_yaml(ycomponent_state, all_hosts)
      if ycomponent_state
        ycomponent_state['containers'].map do |ycontainer|
          Container.from_yaml(ycontainer, all_hosts)
        end
      else
        []
      end
    end
  end
end
