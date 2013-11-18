
module FFI_Yajl
  class Encoder
    attr_accessor :opts

    def self.encode(obj, *args)
      new(*args).encode(obj)
    end

    def initialize(opts = {})
      @opts = opts
    end

    def encode(obj)
      yajl_gen = FFI_Yajl.yajl_gen_alloc(nil, nil)

      # configure the yajl encoder
      FFI_Yajl.yajl_gen_config(yajl_gen, :yajl_gen_beautify, :int, 1) if opts[:pretty]
      FFI_Yajl.yajl_gen_config(yajl_gen, :yajl_gen_validate_utf8, :int, 1)
      indent = if opts[:pretty]
                 opts[:indent] ? opts[:indent] : "  "
               else
                 " "
               end
      FFI_Yajl.yajl_gen_config(yajl_gen, :yajl_gen_indent_string, :string, indent)

      # setup our own state
      state = {
        :json_opts => opts,
        :processing_key => false,
      }

      # do the encoding
      obj.ffi_yajl(yajl_gen, state)

      # get back our encoded JSON
      string_ptr = FFI::MemoryPointer.new(:string)
      length_ptr = FFI::MemoryPointer.new(:int)
      FFI_Yajl.yajl_gen_get_buf(yajl_gen, string_ptr, length_ptr)
      length = length_ptr.read_int
      string = string_ptr.get_pointer(0).read_string

      return string
    ensure
      # free up the yajl encoder
      FFI_Yajl.yajl_gen_free(yajl_gen)
    end
  end

end


class Hash
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_map_open(yajl_gen)
    self.each do |key, value|
      # Perf Fix: mutate state hash rather than creating new copy
      state[:processing_key] = true
      key.ffi_yajl(yajl_gen, state)
      state[:processing_key] = false
      value.ffi_yajl(yajl_gen, state)
    end
    FFI_Yajl.yajl_gen_map_close(yajl_gen)
  end
end

class Array
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_array_open(yajl_gen)
    self.each do |value|
      value.ffi_yajl(yajl_gen, state)
    end
    FFI_Yajl.yajl_gen_array_close(yajl_gen)
  end
end

class NilClass
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_null(yajl_gen)
  end
end

class TrueClass
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_bool(yajl_gen, 0)
  end
end

class FalseClass
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_bool(yajl_gen, 1)
  end
end

class Fixnum
  def ffi_yajl(yajl_gen, state)
    if state[:processing_key]
      str = self.to_s
      FFI_Yajl.yajl_gen_string(yajl_gen, str, str.length)
    else
      FFI_Yajl.yajl_gen_integer(yajl_gen, self)
    end
  end
end

class Bignum
  def ffi_yajl(yajl_gen, state)
    raise NotImpelementedError
  end
end

class Float
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_double(yajl_gen, self)
  end
end

class String
  def ffi_yajl(yajl_gen, state)
    FFI_Yajl.yajl_gen_string(yajl_gen, self, self.length)
  end
end

# I feel dirty
class Object
  unless defined?(ActiveSupport)
    def to_json(*args, &block)
      "\"#{to_s}\""
    end
  end

  def ffi_yajl(yajl_gen, state)
    json = self.to_json(state[:json_opts])
    FFI_Yajl.yajl_gen_number(yajl_gen, json, json.length)
  end
end

