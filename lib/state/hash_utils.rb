require_relative '../constants'
require_relative '../hash_utils'

module Rook
  module State
    HASH_UTILS = HashUtils.new(StateFileLoadError)
  end
end
