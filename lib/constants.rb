module Rook
  class ConfigError < StandardError; end
  class RequiredKeyError < ConfigError; end

  LATEST_STATE_VERSION = "1.0".freeze
end
