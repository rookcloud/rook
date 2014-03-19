require_relative '../constants'
require_relative '../hash_utils'

module Rook
  module Config
    HASH_UTILS = HashUtils.new(ConfigFileLoadError)
  end
end
