# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atleisure/version'

Gem::Specification.new do |gem|
  gem.name          = "atleisure"
  gem.version       = Atleisure::VERSION
  gem.authors       = ["Roomorama Developers"]
  gem.email         = ["developers@roomorama.com"]
  gem.description   = %q{Provides methods to access the atleisure API.}
  gem.summary       = %q{Atleisure API Client}
  gem.homepage      = "https://github.com/roomorama/"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('jimson')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('debugger')
end
