source 'https://rubygems.org'

gemspec

# Runtime dependency
if RUBY_VERSION >= '3.1'
  gem 'rack', github: 'rack/rack'
else
  gem 'rack', '~> 2.0'
end

# We can't add Rubocop as dev. dependency in gemspec
# since it is not installable with archaic Rubies
gem 'rubocop', '~> 1.28.1' if RUBY_VERSION >= '2.5.0'
