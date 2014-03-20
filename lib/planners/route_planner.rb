require_relative '../default_logger'
require_relative '../state/route'
require_relative '../state/service_port_redirection'

module Rook
  class RoutePlanner
    class Service
      # The container that provides the service.
      attr_accessor :container
      # The port, inside the container, on which the service listens.
      attr_accessor :service_port

      def initialize(container, service_port)
        @container = container
        @service_port = service_port
      end

      def host
        @container.host
      end
    end

    attr_accessor :logger

    def initialize(options = {})
      @config = options[:config] || raise(ArgumentError, ":config must be given")
      @state  = options[:state]  || raise(ArgumentError, ":state must be given")
      @logger = options[:logger] || Rook.default_logger
      @source_port_range = options[:source_port_range] || (11000..12000)
      @host_port_range   = options[:host_port_range]   || (17000..18000)
    end

    def run
      consumers, services = collect_consumers_and_services
      plan_routes(consumers, services)
      plan_host_to_container_port_redirections(services)
      plan_route_source_ports(consumers)
    end

  private
    def collect_consumers_and_services
      consumers = []
      services = []
      @state.components.each do |component|
        component.containers.each do |container|
          if component.consumes_services?
            consumers << container
          end
          component.service_ports.each do |service_port|
            services << Service.new(container, service_port)
          end
        end
      end
      [consumers, services]
    end

    def plan_routes(consumers, services)
      consumers.each do |consumer|
        valid_routes = []
        services.each do |service|
          if consumer != service.container
            route = plan_route_for_consumer_to_service(consumer, service)
            valid_routes << route
          end
        end

        removed_routes = []
        consumer.routes.each do |route|
          if !valid_routes.include?(route)
            removed_routes << route
          end
        end

        removed_routes.each do |route|
          logger.info "Route no longer necessary: #{route}"
          consumer.routes.delete(route)
        end
      end
    end

    def plan_route_for_consumer_to_service(consumer, service)
      if route = consumer.find_route_to(service.container, service.service_port)
        logger.info "Existing route still valid: #{route}"
      else
        route = State::Route.new
        route.source = consumer
        route.destination = service.container
        route.service_port = service.service_port
        consumer.routes << route
        logger.info "Planning new route: #{route}"
      end
      route
    end

    def plan_host_to_container_port_redirections(services)
      @state.components.each do |component|
        component.containers.each do |container|
          container.service_port_redirections.clear
        end
      end
      @state.hosts.each do |host|
        host.service_port_redirections.clear
      end
      services.each do |service|
        host_port = pick_available_service_port_on_host(service.host)
        service.container.service_port_redirections[service.service_port] = host_port
        redirection = State::ServicePortRedirection.new
        redirection.host_port = host_port
        redirection.container = service.container
        redirection.service_port = service.service_port
        service.host.service_port_redirections[host_port] = redirection
      end
    end

    def pick_available_service_port_on_host(host)
      # TODO: detect when we're out of ports
      while true
        host_port = pick_random_from_range(@host_port_range)
        if !host.service_port_redirections.has_key?(host_port)
          return host_port
        end
      end
    end

    def plan_route_source_ports(consumers)
      consumers.each do |consumer|
        consumer.routes.each do |route|
          if route.source_port.nil?
            route.source_port = pick_available_source_port_in_container(route.source)
            logger.debug "Assigning source port #{route.source_port} to route #{route}"
          end
        end
      end
    end

    def pick_available_source_port_in_container(container)
      # TODO: detect when we're out of ports
      while true
        source_port = pick_random_from_range(@source_port_range)
        if !container.route_source_port_used?(source_port)
          return source_port
        end
      end
    end

    def pick_random_from_range(range)
      range.first + rand(range.last - range.first)
    end
  end
end
