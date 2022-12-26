source 'https://rubygems.org'

gemspec

# Runtime dependency
if RUBY_VERSION >= '3.1'
  if RUBY_VERSION < '3.2'
    gem 'cgi', '0.3.6'
  end
  gem 'rack', github: 'rack/rack'
else
  gem 'rack', '~> 2.0'
end
