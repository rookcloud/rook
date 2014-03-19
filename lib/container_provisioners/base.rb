require 'logger'
require_relative '../container'

module Rook
  # Abstract base class for container provisioners.
  class BaseContainerProvisioner
    attr_accessor :logger

    def initialize(options = {})
      @logger = options[:logger] || Logger.new(STDOUT)
    end
  end
end
