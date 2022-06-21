require_relative 'lib/rack/test/version'

Gem::Specification.new do |s|
  s.name = 'rack-test'
  s.version = Rack::Test::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = ['Jeremy Evans', 'Bryan Helmkamp']
  s.email = ['code@jeremyevans.net', 'bryan@brynary.com']
  s.license = 'MIT'
  s.homepage = 'https://github.com/rack/rack-test'
  s.summary = 'Simple testing API built on Rack'
  s.description = <<-EOS.strip
Rack::Test is a small, simple testing API for Rack apps. It can be used on its
own or as a reusable starting point for Web frameworks and testing libraries
to build on.
  EOS
  s.metadata = {
    'source_code_uri'   => 'https://github.com/rack/rack-test',
    'bug_tracker_uri'   => 'https://github.com/rack/rack-test/issues',
    'mailing_list_uri'  => 'https://github.com/rack/rack-test/discussions',
    'changelog_uri'     => 'https://github.com/rack/rack-test/blob/main/History.md',
  }
  s.require_paths = ['lib']
  s.files = `git ls-files -- lib/*`.split("\n") +
            %w[History.md MIT-LICENSE.txt README.md]
  s.required_ruby_version = '>= 2.0'
  s.add_dependency 'rack', '>= 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest', ">= 5.0"
  s.add_development_dependency 'minitest-global_expectations'
end
