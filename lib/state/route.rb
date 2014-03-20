module Rook
  module State
    class Route
      # The container that needs a route to a service.
      attr_accessor :source
      # The port, inside the source container, that is to be connected
      # to the destination service.
      attr_accessor :source_port
      # The destination container.
      attr_accessor :destination
      # The service port inside the destination container.
      attr_accessor :service_port

      def as_yaml
        {
          'container'  => @destination.id,
          'service_port' => @service_port
        }
      end

      def to_s
        "#{source} -> #{destination} port #{service_port}"
      end
    end
  end
end
