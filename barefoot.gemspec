# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barefoot/version'

Gem::Specification.new do |gem|
  gem.name          = "barefoot"
  gem.version       = Barefoot::VERSION
  gem.authors       = ["Roomorama Developers"]
  gem.email         = ["developers@roomorama.com"]
  gem.description   = %q{Provides methods to access the Barefoot API.}
  gem.summary       = %q{Barefoot API Client}
  gem.homepage      = "https://github.com/roomorama/"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('savon')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('debugger')
end
