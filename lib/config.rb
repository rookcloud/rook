require_relative 'safe_yaml'
require_relative 'hash_utils'
require_relative 'host'
require_relative 'component'

module Rook
  class Config
    attr_accessor :state_version, :name, :components, :hosts

    def initialize(config_path, state_path = nil)
      @config_path = config_path
      @state_path  = state_path || default_state_path(config_path)
      load
    end

    def single_host?
      !!@sole_host
    end

    def sole_host
      if @sole_host
        @sole_host
      else
        raise "#sole_host may only be called in single-host mode"
      end
    end

    def find_component(type)
      @components.find { |c| c.type == type }
    end

    def find_empty_hosts
      @hosts.find_all { |h| h.containers.empty? }
    end

    def write_state(io = nil)
      if io
        YAML.dump(state_as_yaml, io)
      else
        temp_path = @state_path + ".tmp"
        File.open(temp_path, "w") do |f|
          YAML.dump(state_as_yaml, f)
          f.flush
          f.fsync
        end
        File.rename(temp_path, @state_path)
      end
    end

    def state_as_yaml
      result = {}
      result['state_version'] = @state_version
      result['components'] = components_as_yaml
      result['hosts'] = hosts_as_yaml
      result
    end

  private
    def default_state_path(config_path)
      config_path + ".state"
    end

    def load
      yconfig = YAML.load_file(@config_path)
      ystate  = YAML.load_file(@state_path)

      @state_version = HashUtils.get_str!(ystate, 'state_version')
      @name = HashUtils.get_str!(yconfig, 'name')

      if yconfig['use_single_host']
        yhost = yconfig['use_single_host'].dup
        yhost['name'] = HashUtils.get_str(yhost, 'name', "Main Rook host")
        @sole_host = Host.from_yaml(yhost)
      end

      load_hosts(yconfig, ystate)
      load_components(yconfig, ystate)
      fixup_sole_host
      upgrade_state_version
    end

    def load_hosts(yconfig, ystate)
      @hosts = []
      ystate['hosts'].each do |yhost|
        @hosts << Host.from_yaml(yhost)
      end
    end

    def load_components(yconfig, ystate)
      @components = []
      yconfig['components'].each do |ycomponent|
        type = ycomponent['type']
        ycomponent_state = ystate['components'].find { |ycomponent| ycomponent['type'] == type }
        component = Component.from_yaml(self, ycomponent, ycomponent_state, @hosts)
        @components << component
      end
    end

    def fixup_sole_host
      if @sole_host
        if new_sole_host = @hosts.find { |host| host.equivalent?(@sole_host) }
          new_sole_host.name = @sole_host.name
          @sole_host = new_sole_host
        end
      end
    end

    def upgrade_state_version
      @state_version = LATEST_STATE_VERSION
    end

    def components_as_yaml
      result = []
      @components.each do |component|
        result << component.as_state_yaml
      end
      result
    end

    def hosts_as_yaml
      result = []
      @hosts.each do |host|
        result << host.as_state_yaml
      end
      result
    end
  end
end
