
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'badev/version'

Gem::Specification.new do |spec|
  spec.name          = 'badev'
  spec.version       = Badev::VERSION
  spec.authors       = ['Antonin Hildebrand']
  spec.email         = ['antonin@binaryage.com']
  spec.description   = 'A command-line tool to aid developers in BinaryAge.'
  spec.summary       = 'A command-line tool to aid developers in BinaryAge.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = %w[badev bagen]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'commander'
  spec.add_runtime_dependency 'xcodeproj'
  spec.add_runtime_dependency 'colored2'
end
