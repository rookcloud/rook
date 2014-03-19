require_relative 'hash_utils'
require_relative 'container'

module Rook
  class Component
    attr_accessor :config, :type, :repo_url, :repo_type, :revision, :docker_image,
      :uses_master_slave_replication
    # Desired number of instances. May not match the actually provisioned containers.
    attr_accessor :instances
    # The actually provisioned containers.
    attr_accessor :containers

    def self.from_yaml(config, ycomponent, ycomponent_state, all_hosts)
      component = new(config)
      component.type         = HashUtils.get_str!(ycomponent, 'type')
      component.repo_url     = HashUtils.get_str!(ycomponent_state, 'repo_url')
      component.repo_type    = HashUtils.get_str!(ycomponent_state, 'repo_type')
      component.revision     = HashUtils.get_str!(ycomponent_state, 'revision')
      component.docker_image = HashUtils.get_str!(ycomponent_state, 'docker_image')
      component.uses_master_slave_replication = HashUtils.get_bool(ycomponent_state,
        'uses_master_slave_replication')
      component.instances    = HashUtils.get_int(ycomponent, 'instances', 1)
      component.containers   = load_containers_from_yaml(ycomponent_state, all_hosts)
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

    alias uses_master_slave_replication? uses_master_slave_replication

    def as_state_yaml
      {
        'type'         => @type,
        'repo_url'     => @repo_url,
        'repo_type'    => @repo_type,
        'revision'     => @revision,
        'docker_image' => @docker_image,
        'uses_master_slave_replication' => uses_master_slave_replication?,
        'containers'   => @containers.map { |c| c.as_state_yaml }
      }
    end

  private
    def self.load_containers_from_yaml(ycomponent_state, all_hosts)
      HashUtils.get(ycomponent_state, 'containers', []).map do |ycontainer|
        Container.from_yaml(ycontainer, all_hosts)
      end
    end
  end
end
