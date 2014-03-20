require_relative '../constants'
require_relative 'route'
require_relative 'hash_utils'

module Rook
  module State
    class Container
      attr_accessor :id, :host, :routes, :service_port_redirections
      attr_accessor :planned_action

      def self.from_yaml(yaml, all_hosts)
        host_name      = HASH_UTILS.get_str!(yaml, 'host')
        container      = new
        container.id   = HASH_UTILS.get_str!(yaml, 'id')
        container.host = all_hosts.find { |h| h.name == host_name }
        if container.host.nil?
          raise StateFileLoadError, "Host #{host_name.inspect} not found in the state file's 'hosts' section"
        end
        container.routes = container.send(:load_routes, yaml)
        container.service_port_redirections = container.send(:load_service_port_redirections, yaml)
        container.host.containers << container
        container
      end

      def initialize
        @routes = []
        @service_port_redirections = {}
      end

      def find_route_to(container, service_port)
        @routes.find do |route|
          route.destination == container && route.service_port == service_port
        end
      end

      def route_source_port_used?(port)
        @routes.any? { |route| route.source_port == port }
      end

      def as_yaml
        result = {
          'id'   => @id,
          'host' => @host.name
        }
        if !@routes.empty?
          result['routes'] = routes_as_yaml
        end
        if !@service_port_redirections.empty?
          result['service_port_redirections'] = @service_port_redirections
        end
        result
      end

      def to_s
        id
      end

    private
      def load_routes(yaml)
        if yaml && (yroutes = yaml['routes'])
          routes = []
          yroutes.each_pair do |source_port, yroute|
            route = Route.new
            route.source = self
            route.source_port = source_port.to_i
            # Will be changed into a Container object by File#associate_route_destinations.
            route.destination = HASH_UTILS.get_str!(yroute, 'container')
            route.service_port = HASH_UTILS.get_int!(yroute, 'service_port')
            routes << route
          end
          routes
        else
          []
        end
      end

      def load_service_port_redirections(yaml)
        if yaml && (yredirections = yaml['service_port_redirections'])
          result = {}
          yredirections.each_pair do |source_port, host_port|
            result[source_port.to_i] = host_port.to_i
          end
          result
        else
          {}
        end
      end

      def routes_as_yaml
        result = {}
        @routes.each do |route|
          result[route.source_port] = route.as_yaml
        end
        result
      end
    end
  end
end
