#!/usr/bin/env ruby
require_relative 'lib/config/file'
require_relative 'lib/state/file'
require_relative 'lib/planners/infrastructure_change_planner'
require_relative 'lib/planners/route_planner'
require_relative 'lib/container_manager'

module Rook
  class DevelopCommand
    def initialize(config, state)
      @config = config
      @state  = state
      @app_path = File.absolute_path(".")
    end

    def run
      plan_infrastructure_change
      plan_routes
      install_containers
      restart_containers
    end

  private
    def plan_infrastructure_change
      planner = InfrastructureChangePlanner.new(
        :config => @config,
        :state => @state)
      planner.run
    end

    def plan_routes
      planner = RoutePlanner.new(:config => @config, :state => @state)
      planner.run
    end

    def install_containers
      each_container do |container|
        if container.planned_action == :create
          Rook.default_logger.info "Installing #{container} on #{container.host}"
          manager = ContainerManager.new(@config, container)
          manager.install
        end
      end
    end

    def restart_containers
      each_container do |container|
        Rook.default_logger.info "Restarting #{container} on #{container.host}"
        manager = ContainerManager.new(@config, container)
        manager.restart
      end
    end

    def each_container
      @state.components.each do |component|
        component.containers.each do |container|
          yield container
        end
      end
    end
  end
end

config = Rook::Config::File.load_file("Rookfile", :development_mode => true)
state  = Rook::State::File.new_for_config(config, "Rookfile.state")
command = Rook::DevelopCommand.new(config, state)
command.run
state.write(STDOUT)
