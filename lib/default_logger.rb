require 'logger'

module Rook
  def self.default_logger
    @@default_logger ||= Logger.new(STDOUT)
  end
end
