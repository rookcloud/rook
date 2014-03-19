require_relative '../default_logger'
require_relative '../state/container'

module Rook
  # Abstract base class for container provisioners.
  class BaseContainerProvisioner
    attr_reader :options
    attr_accessor :logger

    def initialize(options = {})
      @options = options.dup
      @logger  = (options[:logger] ||= Rook.default_logger)
    end
  end
end
