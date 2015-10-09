gemspec = eval(IO.read(File.expand_path(File.join(File.dirname(__FILE__), "ffi-yajl.gemspec.shared"))))

gemspec.platform = "x86-mingw32"

gemspec.add_runtime_dependency "ffi", "~> 1.5"

gemspec
