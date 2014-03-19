module Rook
  class ConfigFileLoadError < StandardError; end
  class RequiredKeyError < ConfigFileLoadError; end
  class StateFileLoadError < StandardError; end

  LATEST_STATE_FILE_VERSION = "1.0".freeze
  SSH_DEFAULT_PORT = 22

  # Attributes common to Config::Component and State::Component.
  COMPONENT_COMMON_ATTRIBUTES = [:type, :repo_url, :repo_type, :revision,
  	:docker_image, :uses_master_slave_replication]
end
