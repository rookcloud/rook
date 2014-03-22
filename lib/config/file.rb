require_relative '../safe_yaml'
require_relative '../constants'
require_relative '../utils'
require_relative 'hash_utils'
require_relative 'component'
require_relative 'host'

module Rook
  module Config
    class File
      attr_reader :path
      attr_accessor :rookdir, :components

      def self.load_file(path, options = {})
        file = new(path, options)
        file.load
        file
      end

      def initialize(path, options = {})
        @development_mode = options[:development_mode]
        @components = []
        @path = path
        @rookdir = ::File.join(::File.dirname(path), "rookdir")
        if @development_mode
          @single_host = Host.from_yaml(
            'name' => 'Rook main host',
            'address' => '127.0.0.1')
        end
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

      def use_vagrant?
        @use_vagrant || !Utils.on_linux?
      end

      def app_path
        File.absolute_path(File.dirname(@path))
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
        if !@development_mode && (info = yaml['use_single_host'])
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
