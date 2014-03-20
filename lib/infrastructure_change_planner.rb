require_relative 'default_logger'
require_relative 'component_scaling_planner'
require_relative 'utils'

module Rook
  class InfrastructureChangePlanner
    attr_accessor :logger

    def initialize(options = {})
      @options = options.dup
      @logger  = (@options[:logger] ||= Rook.default_logger)
      @config  = options[:config] || raise(ArgumentError, ":config must be given")
      @state   = options[:state]  || raise(ArgumentError, ":state must be given")
    end

    def run
      new_components, existing_components, removed_components = categorize_components

      new_components.each do |cconfig|
        plan_component_creation(cconfig)
      end

      existing_components.each do |item|
        cconfig, cstate = item
        plan_component_scaling(cconfig, cstate)
      end

      removed_components.each do |cstate|
        plan_component_deprovisioning(cstate)
      end

      #deprovision_empty_hosts
    end

  private
    def categorize_components
      new_components = []
      existing_components = []
      removed_components = []

      @config.components.each do |cconfig|
        if cstate = @state.find_component(cconfig.type)
          existing_components << [cconfig, cstate]
        else
          new_components << cconfig
        end
      end

      @state.components.each do |cstate|
        if @config.find_component(cstate.type).nil?
          removed_components << cstate
        end
      end

      [new_components, existing_components, removed_components]
    end

    def plan_component_creation(cconfig)
      logger.info "Detected new component: #{cconfig.type}"
      cstate = State::Component.new(@state)
      cstate.copy_attributes_from_config_component(cconfig)
      @state.components << cstate
      Utils.assert { cstate.instances == 0 }
      planner = ComponentScalingPlanner.new(@options.merge(
        :config_component => cconfig,
        :state_component => cstate))
      planner.run
    end

    def plan_component_scaling(cconfig, cstate)
      planner = ComponentScalingPlanner.new(@options.merge(
        :config_component => cconfig,
        :state_component => cstate))
      planner.run
    end

    def plan_component_deprovisioning(cstate)
      logger.info "Detected removed component: #{cstate.type}"
      cconfig = Config::Component.new(@config)
      cconfig.copy_attributes_from_state_component(cstate)
      cconfig.instances = 0
      planner = ComponentScalingPlanner.new(@options.merge(
        :config_component => cconfig,
        :state_component => cstate))
      planner.run
      @state.components.delete(cstate)
    end

    # def deprovision_empty_hosts
    #   empty_hosts = @state.find_empty_hosts
    #   if !empty_hosts.empty?
    #     logger.info("The following hosts no longer have any containers: #{empty_hosts}")
    #     @host_provisioner.deprovision(empty_hosts)
    #     @state.remove_hosts(empty_hosts)
    #   end
    # end
  end
end
