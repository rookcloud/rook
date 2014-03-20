module Rook
  class ConfigFileLoadError < StandardError; end
  class RequiredKeyError < ConfigFileLoadError; end
  class StateFileLoadError < StandardError; end

  LATEST_STATE_FILE_VERSION = "1.0".freeze
  SSH_DEFAULT_PORT = 22

  # Attributes common between Config::Component and State::Component.
  COMPONENT_COMMON_ATTRIBUTES = [:type, :docker_image, :consumes_services,
  	:service_ports, :app_server, :uses_master_slave_replication].freeze
end
