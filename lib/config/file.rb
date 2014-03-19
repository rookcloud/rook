require_relative '../safe_yaml'
require_relative '../constants'
require_relative 'hash_utils'
require_relative 'component'
require_relative 'host'

module Rook
  module Config
    class File
      attr_accessor :path
      attr_accessor :components

      def self.load_file(path)
        file = new
        file.path = path
        file.load
        file
      end

      def initialize
        @components = []
      end

      def single_host?
        !!@single_host
      end

      def sole_host
        if single_host?
          @single_host
        else
          raise "#sole_host may only be called in single-host mode"
        end
      end

      def find_component(type)
        @components.find { |c| c.type == type }
      end

      def load
        yaml = YAML.load_file(@path)
        load_single_hosts(yaml)
        load_components(yaml)
      end

    private
      def load_single_hosts(yaml)
        if info = yaml['use_single_host']
          @single_host = Host.from_yaml(info)
        end
      end

      def load_components(yaml)
        if !yaml['components'].is_a?(Array)
          raise ConfigFileLoadError, "No valid 'components' section found"
        end

        @components = []
        yaml['components'].each do |ycomponent|
          if !ycomponent.is_a?(Hash)
            raise ConfigFileLoadError, "The 'components' section contains an invalid entry"
          end
          @components << Component.from_yaml(self, ycomponent)
        end
      end
    end
  end
end
