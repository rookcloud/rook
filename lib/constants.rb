module Rook
  class ConfigFileLoadError < StandardError; end
  class RequiredKeyError < ConfigFileLoadError; end
  class StateFileLoadError < StandardError; end

  LATEST_STATE_FILE_VERSION = "1.0".freeze
  SSH_DEFAULT_PORT = 22
end
