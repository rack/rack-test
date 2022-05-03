require_relative '../../spec_helper'

describe 'Rack::Test::Session digest authentication' do
  app = Rack::Auth::Digest::MD5.new(Rack::Test::FakeApp.new.freeze) do |username|
    { 'alice' => 'correct-password' }[username]
  end
  app.realm = 'WallysWorld'
  app.opaque = 'this-should-be-secret'
  define_method(:app) { app }

  it 'incorrectly authenticates GETs' do
    digest_authorize 'foo', 'bar'
    get '/'
    last_response.status.must_equal 401
    last_response['WWW-Authenticate'].must_match(/\ADigest /)
    last_response.body.must_be_empty
  end

  it 'correctly authenticates GETs' do
    digest_authorize 'alice', 'correct-password'
    get('/').must_be :ok?
  end

  it 'correctly authenticates GETs with params' do
    digest_authorize 'alice', 'correct-password'
    get('/', 'foo' => 'bar').must_be :ok?
  end

  it 'correctly authenticates POSTs' do
    digest_authorize 'alice', 'correct-password'
    post('/').must_be :ok?
  end

  it 'returns a re-challenge if authenticating incorrectly' do
    digest_authorize 'alice', 'incorrect-password'
    get '/'
    last_response.status.must_equal 401
    last_response['WWW-Authenticate'].must_match(/\ADigest /)
    last_response.body.must_be_empty
  end
end
