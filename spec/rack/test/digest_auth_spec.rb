# frozen-string-literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rack/test/mock_digest_request'

describe 'Rack::Test::Session digest authentication' do
  app = Rack::Auth::Digest::MD5.new(Rack::Test::FakeApp.new.freeze) do |username|
    { 'alice' => 'correct-password' }[username]
  end
  app.realm = 'WallysWorld'
  app.opaque = 'this-should-be-secret'
  define_method(:app) { app }

  deprecated 'incorrectly authenticates GETs' do
    digest_authorize 'foo', 'bar'
    get '/'
    last_response.status.must_equal 401
    last_response['WWW-Authenticate'].must_match(/\ADigest /)
    last_response.body.must_be_empty
  end

  deprecated 'correctly authenticates GETs' do
    digest_authorize 'alice', 'correct-password'
    get('/').must_be :ok?
  end

  deprecated 'correctly authenticates GETs with params' do
    digest_authorize 'alice', 'correct-password'
    get('/', 'foo' => 'bar').must_be :ok?
  end

  deprecated 'correctly authenticates POSTs' do
    digest_authorize 'alice', 'correct-password'
    post('/').must_be :ok?
  end

  deprecated 'returns a re-challenge if authenticating incorrectly' do
    digest_authorize 'alice', 'incorrect-password'
    get '/'
    last_response.status.must_equal 401
    last_response['WWW-Authenticate'].must_match(/\ADigest /)
    last_response.body.must_be_empty
  end
end

describe 'Rack::Test::MockDigestRequest' do
  deprecated '#method_missing will return values based on params if they are present' do
    Rack::Test::MockDigestRequest.new('foo' => 'bar').foo.must_equal 'bar'
  end

  deprecated '#method_missing will raise NoMethodError if param is not present' do
    proc{Rack::Test::MockDigestRequest.new({}).foo}.must_raise NoMethodError
  end
end
