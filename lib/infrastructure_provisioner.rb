require_relative 'default_logger'
require_relative 'host_provisioners/dummy'
require_relative 'container_provisioners/dummy'
require_relative 'component_scaler'

module Rook
  class InfrastructureProvisioner
    attr_accessor :logger

    def initialize(options = {})
      @options = options.dup
      @logger  = (@options[:logger] ||= Rook.default_logger)
      @state   = options[:state]  || raise(ArgumentError, ":state must be given")
      @config  = options[:config] || raise(ArgumentError, ":config must be given")
      @host_provisioner = (@options[:host_provisioner] ||= DummyHostProvisioner.new(:logger => @logger))
      @options[:container_provisioner] ||= DummyContainerProvisioner.new(:logger => @logger)
    end

    def run
      new_components, existing_components, removed_components = categorize_components

      new_components.each do |desired_component|
        provision_new_component(desired_component)
      end

      existing_components.each do |item|
        current_component, desired_component = item
        update_existing_component(current_component, desired_component)
      end

      removed_components.each do |current_component|
        deprovision_removed_component(current_component)
      end

      deprovision_empty_hosts
    end

  private
    def categorize_components
      new_components = []
      existing_components = []
      removed_components = []

      @config.components.each do |desired_component|
        if current_component = @state.find_component(desired_component.type)
          existing_components << [current_component, desired_component]
        else
          new_components << desired_component
        end
      end

      @state.components.each do |current_component|
        if @config.find_component(current_component.type).nil?
          removed_components << current_component
        end
      end

      [new_components, existing_components, removed_components]
    end

    def provision_new_component(desired_component)
      current_component = State::Component.new
      current_component.copy_attributes_from_config_component(desired_component)
      Utils.assert { current_component.instances == 0 }
      scaler = ComponentScaler.new(@options.merge(
        :current => current_component,
        :desired => desired_component))
      scaler.run
    end

    def update_existing_component(current_component, desired_component)
      scaler = ComponentScaler.new(@options.merge(
        :current => current_component,
        :desired => desired_component))
      scaler.run
    end

    def deprovision_removed_component(current_component)
      desired_component = Config::Component.new
      desired_component.copy_attributes_from_state_component(current_component)
      desired_component.instances = 0
      scaler = ComponentScaler.new(@options.merge(
        :current => current_component,
        :desired => desired_component))
      scaler.run
    end

    def deprovision_empty_hosts
      empty_hosts = @state.find_empty_hosts
      logger.info("The following hosts no longer have any containers: #{empty_hosts}")
      @host_provisioner.deprovision(empty_hosts)
      @state.remove_hosts(empty_hosts)
    end
  end
end
