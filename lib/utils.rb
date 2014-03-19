module Rook
  module Utils
    extend self

    def assert(*args)
      if args.size == 0
        result = yield
      elsif args.size == 1
        result = args[0]
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1)"
      end
      if !result
        raise "Assertion failed"
      end
    end
  end
end
