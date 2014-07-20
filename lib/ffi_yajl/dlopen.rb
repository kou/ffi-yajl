
require 'ffi'

module FFI_Yajl
  module DLopen
  extend FFI::Library
  ffi_lib 'dl'
  attach_function :dlopen, [ :string, :int ], :pointer
end

