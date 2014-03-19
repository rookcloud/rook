module Rook
  class ConfigError < StandardError; end
  class RequiredKeyError < ConfigError; end
end
