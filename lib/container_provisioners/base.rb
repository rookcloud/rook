require_relative '../default_logger'
require_relative '../os_detection'
require_relative '../state/container'

module Rook
  # Abstract base class for container provisioners.
  class BaseContainerProvisioner
    attr_reader :options
    attr_accessor :logger

    def initialize(options = {})
      @options  = options.dup
      @app_path = @options[:app_path] || raise(ArgumentError, ":app_path must be given")
      @logger   = (options[:logger] ||= Rook.default_logger)
    end

  private
    def development_mode?
     	!!@options[:development_mode]
    end

    def using_vagrant?
      @options[:vagrant] || !Rook.linux?
    end
  end
end
