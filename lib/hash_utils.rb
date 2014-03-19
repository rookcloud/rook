require_relative 'constants'

module Rook
  module HashUtils
    extend self

    def get_str(hash, name, default = "")
      if hash.has_key?(name)
        hash[name].to_s
      else
        default
      end
    end

    def get_str!(hash, name)
      if hash.has_key?(name)
        hash[name].to_s
      else
        raise RequiredKeyError, "Key #{name} required"
      end
    end

    def get_int(hash, name, default = 0)
      if hash.has_key?(name)
        hash[name].to_i
      else
        default
      end
    end
  end
end