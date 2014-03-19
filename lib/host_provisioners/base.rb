require 'logger'
require_relative '../host'

module Rook
  # Abstract base class for host provisioners.
  class BaseHostProvisioner
    attr_accessor :logger

    def initialize(options = {})
      @logger = options[:logger] || Logger.new(STDOUT)
    end
  end
end
