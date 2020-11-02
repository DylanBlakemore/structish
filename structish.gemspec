
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "structish/version"

Gem::Specification.new do |spec|
  spec.name          = "structish"
  spec.version       = Structish::VERSION
  spec.authors       = ["Dylan Blakemore"]
  spec.email         = ["dylan.blakemore@gmail.com"]

  spec.summary       = %q{Adding struct-like properties to Ruby Arrays and Hashes}
  spec.description   = %q{Adds validations, function creation, function delegation,
                          and key restrictions to arrays and hashes so that they may
                          function similarly to Structs}

  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "~> 4.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
end
