if ENV.delete('COVERAGE')
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

require 'rspec'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

require 'rack/test'
require File.dirname(__FILE__) + '/fixtures/fake_app'

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rack::Test::Methods

  config.filter_run_when_matching :focus

  def app
    Rack::Test::FAKE_APP
  end

  def check(*args); end
end
