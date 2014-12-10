# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kdiff3/version"

Gem::Specification.new do |s|
  s.name        = "kdiff3"
  s.version     = KDiff3::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = "GNU GPL v2"
  s.authors     = ["L. Preston Sego III"]
  s.email       = "LPSego3+dev@gmail.com"
  s.homepage    = "https://github.com/NullVoxPopuli/kdiff3-rb"
  s.summary     = "kdiff3-#{KDiff3::VERSION}"
  s.description = "Ruby wrapper for the kdiff3 mergetool"


  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.extensions    = ['ext/kdiff3/extconf.rb']

  s.add_dependency 'activesupport'

  s.add_development_dependency "bundler"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "codeclimate-test-reporter"

end