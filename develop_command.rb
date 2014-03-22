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
      planner = InfrastructureChangePlanner.new(
        :config => @config,
        :state => @state)
      planner.run

      planner = RoutePlanner.new(:config => @config, :state => @state)
      planner.run

      @state.hosts.each do |host|
        if host.planned_action == :create
          raise "TODO"
        end
      end

      @state.components.each do |component|
        component.containers.each do |container|
          if container.planned_action == :create
            Rook.default_logger.info "Installing #{container}"
            manager = ContainerManager.new(@config, container)
            manager.install
          end
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
