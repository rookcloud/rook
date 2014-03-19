require_relative '../default_logger'
require_relative '../state/host'

module Rook
  # Abstract base class for host provisioners.
  class BaseHostProvisioner
    attr_reader :options
    attr_accessor :logger

    def initialize(options = {})
      @options = options.dup
      @logger  = (options[:logger] ||= Rook.default_logger)
    end
  end
end
