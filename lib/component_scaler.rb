require_relative 'default_logger'

# TODO: ensure that hosts have unique names
# TODO: check that containers have unique names
# TODO: support transitioning from single host to multi host and vice versa

module Rook
  class ComponentScaler
    attr_accessor :logger

    def initialize(options = {})
      # A State::Component object.
      @current = options[:current] || raise(ArgumentError, ":current must be given")
      # A Config::Component object.
      @desired = options[:desired] || raise(ArgumentError, ":desired must be given")
      @logger  = options[:logger]  || Rook.default_logger
      @host_provisioner = options[:host_provisioner] || raise(ArgumentError, ":host_provisioner must be given")
      @container_provisioner = options[:container_provisioner] || raise(ArgumentError, ":container_provisioner must be given")

      if !@current.attributes_match_config_component?(@desired)
        raise ArgumentError, "Current and desired component states don't have matching attributes"
      end
      if current_state.single_host? != desired_config.single_host?
        if current_state.single_host?
          raise "To transition from a single-host to multi-host setup, use 'rook transition --to-multi-host' instead."
        else
          raise "To transition from a multi-host to single-host setup, use 'rook transition --to-single-host' instead."
        end
      end
    end

    def run
      if @desired.instances > @current.instances
        logger.info("Scaling up #{type}: from #{@current.instances} to #{@desired.instances}")
        scale_up(@desired.instances - @current.instances)
        true
      elsif @desired.instances < @current.instances
        logger.info("Scaling down #{type}: from #{@current.instances} to #{@desired.instances}")
        scale_down(@current.instances - @desired.instances)
        true
      else
        false
      end
    end

  private
    ##### Code for scaling up #####

    def scale_up(count)
      new_containers = add_containers(count)

      if uses_master_slave_replication?
        if @desired.instances == 1
          setup_master_replication(@current.containers[0])
        end
        setup_slaves(new_containers)
      end
    end

    def add_containers(count)
      new_containers = []
      if single_host_setup?
        count.times do
          new_containers << add_container(sole_host)
        end
      else
        provision_hosts(count).each do |host|
          new_containers << add_container(host)
        end
      end
      new_containers
    end

    def provision_hosts(count)
      hosts = @host_provisioner.provision(@desired, count)
      hosts.each do |host|
        current_state.hosts << host
      end
      hosts
    end

    def add_container(host)
      container = @container_provisioner.create(host, @desired)
      container.host = host
      host.containers << container
      @current.containers << container
      container
    end

    def setup_master_replication(container)
      logger.error "setup_master_replication: TODO"
    end

    def setup_slaves(containers)
      logger.error "setup_slaves: TODO"
    end


    ##### Code for scaling down #####

    def scale_down(count)
      find_excess_containers(count).each do |container|
        remove_container(container)
      end

      if uses_master_slave_replication? && @desired.instances == 1
        uninstall_master_replication(@current.containers[0])
      end
    end

    def find_excess_containers(count)
      containers = @current.containers
      containers[(containers.size - count) .. -1]
    end

    def remove_container(container)
      @container_provisioner.destroy(container)
      @current.containers.delete(container)
      container.host.containers.delete(container)
    end

    def uninstall_master_replication(container)
      logger.error "uninstall_master_replication: TODO"
    end


    ##### Helper methods #####

    def type
      @current.type
    end

    def current_state
      @current.state
    end

    def desired_config
      @desired.config
    end

    def single_host_setup?
      current_state.single_host?
    end

    def sole_host
      current_state.sole_host
    end

    def uses_master_slave_replication?
      @current.uses_master_slave_replication?
    end
  end
end
