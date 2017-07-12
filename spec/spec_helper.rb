require 'rubygems'
require 'bundler/setup'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'rack'
require 'rspec'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

require 'rack/test'
require File.dirname(__FILE__) + '/fixtures/fake_app'

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rack::Test::Methods

  def app
    Rack::Lint.new(Rack::Test::FakeApp.new)
  end

  def check(*args); end
end

shared_examples_for 'any #verb methods' do
  it 'requests the URL using VERB' do
    send(verb, '/')

    check expect(last_request.env['REQUEST_METHOD']).to eq(verb.upcase)
    expect(last_response).to be_ok
  end

  it 'uses the provided env' do
    send(verb, '/', {}, 'HTTP_USER_AGENT' => 'Rack::Test')
    expect(last_request.env['HTTP_USER_AGENT']).to eq('Rack::Test')
  end

  it 'yields the response to a given block' do
    yielded = false

    send(verb, '/') do |response|
      expect(response).to be_ok
      yielded = true
    end

    expect(yielded).to be_truthy
  end

  it 'sets the HTTP_HOST header with port' do
    send(verb, 'http://example.org:8080/uri')
    expect(last_request.env['HTTP_HOST']).to eq('example.org:8080')
  end

  it 'sets the HTTP_HOST header without port' do
    send(verb, '/uri')
    expect(last_request.env['HTTP_HOST']).to eq('example.org')
  end

  context 'for a XHR' do
    it 'sends XMLHttpRequest for the X-Requested-With header' do
      send(verb, '/', {}, xhr: true)
      expect(last_request.env['HTTP_X_REQUESTED_WITH']).to eq('XMLHttpRequest')
      expect(last_request).to be_xhr
    end
  end
end
