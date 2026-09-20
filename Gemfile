source 'https://rubygems.org'

gemspec

if RUBY_VERSION >= '2.5' && RUBY_VERSION < '3.2'
  gem 'cgi', '0.3.6'
end

if RUBY_VERSION < "2.3"
  gem 'rack', '< 2'
elsif RUBY_VERSION < "2.4"
  gem 'rack', '< 2.1'
elsif RUBY_VERSION < "2.5"
  gem 'rack', '< 2.2'
elsif RUBY_VERSION < "2.6"
  gem 'rack', '< 3'
elsif RUBY_VERSION < "2.7"
  gem 'rack', '< 3.1'
elsif RUBY_VERSION < "3.0"
  gem 'rack', '< 3.2'
elsif RUBY_VERSION < "3.1"
  gem 'rack', '< 3.3'
elsif RUBY_VERSION > "4.0"
  gem 'rack', github: 'rack/rack'
else
  gem 'rack'
end
