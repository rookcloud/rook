module Rook
  class HashUtils
    def initialize(error_class)
      @error_class = error_class
    end

    def get(hash, name, default = nil)
      if hash && hash.has_key?(name)
        hash[name]
      else
        default
      end
    end

    def get_str(hash, name, default = "")
      if hash && hash.has_key?(name)
        hash[name].to_s
      else
        default
      end
    end

    def get_str!(hash, name)
      if hash && hash.has_key?(name)
        hash[name].to_s
      else
        raise @error_class, "Key #{name.inspect} required"
      end
    end

    def get_int(hash, name, default = 0)
      if hash && hash.has_key?(name)
        hash[name].to_i
      else
        default
      end
    end

    def get_int!(hash, name)
      if hash && hash.has_key?(name)
        hash[name].to_i
      else
        raise @error_class, "Key #{name.inspect} required"
      end
    end

    def get_int_array(hash, name, default = [])
      if hash && value = hash[name]
        if value.is_a?(Array)
          value.map { |x| x.to_i }
        else
          raise @error_class, "Key #{name.inspect} must be an array"
        end
      else
        default
      end
    end

    def get_bool(hash, name, default = false)
      if hash && hash.has_key?(name)
        hash[name].to_s == "true"
      else
        default
      end
    end
  end
end