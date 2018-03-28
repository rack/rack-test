# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack/test/version'

Gem::Specification.new do |s|
  s.name = 'rack-test'
  s.version = Rack::Test::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = 'Bryan Helmkamp'
  s.email = 'bryan@brynary.com'
  s.license = 'MIT'
  s.homepage = 'http://github.com/rack-test/rack-test'
  s.summary = 'Simple testing API built on Rack'
  s.description = <<-EOS.strip
Rack::Test is a small, simple testing API for Rack apps. It can be used on its
own or as a reusable starting point for Web frameworks and testing libraries
to build on. Most of its initial functionality is an extraction of Merb 1.0's
request helpers feature.
  EOS
  s.require_paths = ['lib']
  s.files = `git ls-files -- lib/*`.split("\n") +
            %w[History.md MIT-LICENSE.txt README.md]
  s.required_ruby_version = '>= 2.2.2'
  s.add_dependency 'rack', '>= 1.0', '< 3'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'sinatra', '>= 1.0', '< 3'
  s.add_development_dependency 'rdoc', '~> 5.1'
  s.add_development_dependency 'rubocop', '>= 0.49', '< 0.50'
  s.add_development_dependency 'simplecov', '~> 0.16'
  # For Thorfile. Run "bundle exec thor help" to see the help.
  s.add_development_dependency 'thor', '~>  0.19'
end
