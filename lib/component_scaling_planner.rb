require_relative 'default_logger'

# TODO: check that containers have unique names

module Rook
  class ComponentScalingPlanner
    attr_accessor :logger

    def initialize(options = {})
      # A Config::Component object.
      @cconfig = options[:config_component] || raise(ArgumentError, ":config_component must be given")
      # A State::Component object.
      @cstate = options[:state_component] || raise(ArgumentError, ":config_state must be given")
      @logger  = options[:logger]  || Rook.default_logger

      if @cconfig.type != @cstate.type
        # We explicitly check the type here so that we can produce a more
        # useful error message in case the caller passed two unrelated component
        # objects.
        raise ArgumentError, "Config and state components type mismatch (#{@cconfig.type} vs #{@cstate.type})"
      end
      if !@cstate.attributes_match_config_component?(@cconfig)
        raise ArgumentError, "Config and state components for #{@cstate.type} don't have matching attributes"
      end
      if state.single_host? != config.single_host?
        if state.single_host?
          raise "To transition from a single-host to multi-host setup, use 'rook transition --to-multi-host' instead."
        else
          raise "To transition from a multi-host to single-host setup, use 'rook transition --to-single-host' instead."
        end
      end
    end

    def run
      if @cconfig.instances > @cstate.instances
        logger.info("#{type} needs to be scaled up: from #{@cstate.instances} to #{@cconfig.instances} instance(s)")
        scale_up(@cconfig.instances - @cstate.instances)
        true
      elsif @cconfig.instances < @cstate.instances
        logger.info("#{type} needs to be scaled down: from #{@cstate.instances} to #{@cconfig.instances} instance(s)")
        scale_down(@cstate.instances - @cconfig.instances)
        true
      else
        false
      end
    end

  private
    ##### Code for scaling up #####

    def scale_up(count)
      if single_host_setup?
        count.times do
          plan_container_creation(sole_host)
        end
      else
        plan_host_creation(count).each do |host|
          plan_container_creation(host)
        end
      end
    end

    def plan_host_creation(count)
      hosts = []
      count.times do
        host = State::Host.new
        host.name = state.generate_host_name
        host.planned_action = :create
        state.hosts << host
        hosts << host
        logger.info "Planning creation of new host: #{host}"
      end
      hosts
    end

    def plan_container_creation(host)
      container = State::Container.new
      container.id = "rook-#{state.namespace}-#{type}"
      container.host = host
      container.planned_action = :create
      host.containers << container
      @cstate.containers << container
      logger.info "Planning creation of new container: #{container}"
      container
    end


    ##### Code for scaling down #####

    def scale_down(count)
      find_excess_containers(count).each do |container|
        plan_container_removal(container)
      end
    end

    def find_excess_containers(count)
      containers = @cstate.containers
      containers[(containers.size - count) .. -1]
    end

    def plan_container_removal(container)
      logger.info "Planning removal of container: #{container}"
      container.planned_action = :remove
    end


    ##### Helper methods #####

    def type
      @cstate.type
    end

    def config
      @cconfig.config
    end

    def state
      @cstate.state
    end

    def single_host_setup?
      state.single_host?
    end

    def sole_host
      state.sole_host
    end
  end
end
