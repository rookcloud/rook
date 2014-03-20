require_relative '../safe_yaml'
require_relative '../constants'
require_relative 'hash_utils'
require_relative 'host'
require_relative 'component'

module Rook
  module State
    class File
      attr_accessor :path
      attr_accessor :file_version, :components, :hosts

      def self.load_file(path)
        file = new(path)
        file.load
        file
      end

      def self.new_for_config(config, path)
        file = new(path)
        file.initialize_for_config(config)
        file
      end

      def initialize(path)
        @path = path
        @file_version = LATEST_STATE_FILE_VERSION
        @components = []
        @hosts = []
      end

      def single_host?
        !!@single_host
      end

      def sole_host
        if single_host?
          @hosts.first
        else
          raise "#sole_host may only be called in single-host mode"
        end
      end

      def namespace
        "test"
      end

      def find_component(type)
        @components.find { |c| c.type == type }
      end

      def find_container(id)
        @components.each do |component|
          if result = component.containers.find { |c| c.id == id }
            return result
          end
        end
        nil
      end

      def find_empty_hosts
        @hosts.find_all { |h| h.containers.empty? }
      end

      def generate_host_name
        first = %w(Jolly Happy Awesome Groovy Smoking Zappy Snappy Whacky Springy
          Spongy Speedy Funky Sunny Warm Shiny).sample
        last = %w(Tree Grass Flower Bush
          Tomato Apple Orange Mango
          Cloud Rock Stone Hill Mountain Lake
          House Hut Tower
          Car Bike Skate Saucer Mobile
          Bird Bear Turtle Cat Duck Puppy Fish Dino
        ).sample
        # TODO: autodetect when we're out of names
        while true
          name = "#{first} #{last}"
          if @hosts.none? { |h| h.name == name }
            return name
          end
        end
      end

      def remove_hosts(hosts)
        if single_host?
          raise "Cannot remove hosts in single-host mode"
        else
          hosts = [hosts].flatten
          hosts.each do |host|
            if !host.containers.empty?
              raise "Cannot remove host with non-zero number of containers: #{host}"
            end
            @hosts.delete(host)
          end
        end
      end

      def initialize_for_config(config)
        if config.single_host?
          @single_host = true
          host = Host.new
          host.name = config.sole_host.name
          host.address = config.sole_host.address
          host.ssh_port = config.sole_host.ssh_port
          @hosts << host
        end
      end

      def load
        yaml = YAML.load_file(@path)

        load_basics(yaml)
        load_hosts(yaml)
        load_components(yaml)

        associate_route_destinations
        associate_host_service_port_redirection_containers
        upgrade_file_version
      end

      def write(io = nil)
        if io
          YAML.dump(as_yaml, io)
        else
          temp_path = "#{@path}.tmp"
          File.open(temp_path, "w") do |f|
            YAML.dump(as_yaml, f)
            f.flush
            f.fsync
          end
          File.rename(temp_path, @state_path)
        end
      end

      def as_yaml
        result = {}
        result['file_version'] = @file_version
        result['single_host'] = single_host?
        result['components'] = components_as_yaml
        result['hosts'] = hosts_as_yaml
        result
      end

    private
      def load_basics(yaml)
        @file_version = HASH_UTILS.get_str!(yaml, 'file_version')
        @single_host  = HASH_UTILS.get_bool(yaml, 'single_host')
      end

      def load_hosts(yaml)
        if !yaml['hosts'].is_a?(Array)
          raise StateFileLoadError, "No valid 'hosts' section found"
        end

        @hosts = []
        yaml['hosts'].each do |yhost|
          if !yhost.is_a?(Hash)
            raise StateFileLoadError, "The 'hosts' section contains an invalid entry"
          end
          @hosts << Host.from_yaml(yhost)
        end

        if single_host? && @hosts.size != 1
          raise StateFileLoadError, "The 'hosts' section contains #{@hosts.size} entries, " +
            "but this conflicts with the 'single_host' flag"
        end
      end

      def load_components(yaml)
        if !yaml['components'].is_a?(Array)
          raise StateFileLoadError, "No valid 'components' section found"
        end

        @components = []
        yaml['components'].each do |ycomponent|
          if !ycomponent.is_a?(Hash)
            raise StateFileLoadError, "The 'components' section contains an invalid entry"
          end
          @components << Component.from_yaml(self, ycomponent, @hosts)
        end
      end

      def associate_route_destinations
        @components.each do |component|
          component.containers.each do |container|
            container.routes.each do |route|
              container = find_container(route.destination)
              if container
                route.destination = container
              else
                raise StateFileLoadError, "Cannot find component #{route.destination.inspect}, " +
                  "as referenced by a route in #{component.type}"
              end
            end
          end
        end
      end

      def associate_host_service_port_redirection_containers
        @hosts.each do |host|
          host.service_port_redirections.each_value do |redirection|
            container = find_container(redirection.container)
            if container
              redirection.container = container
            else
              raise StateFileLoadError, "Cannot find component #{redirection.container.inspect}, " +
                "as referenced by a service port redirection in host #{host}"
            end
          end
        end
      end

      def upgrade_file_version
        @file_version = LATEST_STATE_FILE_VERSION
      end

      def components_as_yaml
        result = []
        @components.each do |component|
          result << component.as_yaml
        end
        result
      end

      def hosts_as_yaml
        result = []
        @hosts.each do |host|
          result << host.as_yaml
        end
        result
      end
    end
  end
end
