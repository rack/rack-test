source 'https://rubygems.org'

gemspec

# Runtime dependency
if RUBY_VERSION < '2.1'
  gem 'rack', '< 1.4'
else
  gem 'rack', '< 2'
end
