#!/usr/bin/env ruby
require_relative 'lib/config/file'
require_relative 'lib/state/file'
require_relative 'lib/container_provisioners/docker'
require_relative 'lib/infrastructure_provisioner'

module Rook
  class DevelopCommand
    def initialize(config, state)
      @config = config
      @state  = state
      @app_path = File.absolute_path(".")
    end

    def run
      container_provisioner = DockerProvisioner.new(
        :app_path => @app_path,
        :development_mode => true)
      provisioner = InfrastructureProvisioner.new(
        :config => @config,
        :state => @state,
        :host_provisioner => DummyHostProvisioner.new,
        :container_provisioner => container_provisioner)
      provisioner.run
    end
  end
end

config = Rook::Config::File.load_file("Rookfile", :development_mode => true)
state  = Rook::State::File.new_for_config(config, "Rookfile.state")
command = Rook::DevelopCommand.new(config, state)
#command.run
state.write(STDOUT)
