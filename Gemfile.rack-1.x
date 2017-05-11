source 'https://rubygems.org'

gemspec

# Runtime dependency
gem 'rack', '< 2'

# Development dependency
gem 'rake'
gem 'rspec'
gem 'sinatra'
# Keep version < 1 to supress deprecated warning temporary.
gem 'codeclimate-test-reporter', '< 1', :require => false
