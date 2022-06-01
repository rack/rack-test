# frozen-string-literal: true

require_relative '../spec_helper'

describe 'Rack::Test::Session' do
  it 'has alias of Rack::MockSession for backwards compatibility' do
    Rack::MockSession.must_be_same_as Rack::Test::Session
  end

  deprecated 'allows requiring rack/mock_session' do
    require 'rack/mock_session'
  end

  it 'supports being initialized with a Rack::MockSession app' do
    Rack::Test::Session.new(Rack::MockSession.new(app)).request('/').must_be :ok?
  end

  it 'supports being initialized with an app' do
    Rack::Test::Session.new(app).request('/').must_be :ok?
  end
end

describe 'Rack::Test::Session#request' do
  it 'requests the URI using GET by default' do
    request '/'
    last_request.env['REQUEST_METHOD'].must_equal 'GET'
    last_response.must_be :ok?
  end

  it 'returns last response' do
    request('/').must_be :ok?
  end

  it 'uses the provided env' do
    request '/', 'X-Foo' => 'bar'
    last_request.env['X-Foo'].must_equal 'bar'
  end

  it 'allows HTTP_HOST to be set' do
    request '/', 'HTTP_HOST' => 'www.example.ua'
    last_request.env['HTTP_HOST'].must_equal 'www.example.ua'
  end

  it 'sets HTTP_HOST with port for non-default ports' do
    request 'http://foo.com:8080'
    last_request.env['HTTP_HOST'].must_equal 'foo.com:8080'
    request 'https://foo.com:8443'
    last_request.env['HTTP_HOST'].must_equal 'foo.com:8443'
  end

  it 'sets HTTP_HOST without port for default ports' do
    request 'http://foo.com'
    last_request.env['HTTP_HOST'].must_equal 'foo.com'
    request 'http://foo.com:80'
    last_request.env['HTTP_HOST'].must_equal 'foo.com'
    request 'https://foo.com:443'
    last_request.env['HTTP_HOST'].must_equal 'foo.com'
  end

  it 'defaults the REMOTE_ADDR to 127.0.0.1' do
    request '/'
    last_request.env['REMOTE_ADDR'].must_equal '127.0.0.1'
  end

  it 'sets rack.test to true in the env' do
    request '/'
    last_request.env['rack.test'].must_equal true
  end

  it 'defaults to port 80' do
    request '/'
    last_request.env['SERVER_PORT'].must_equal '80'
  end

  it 'defaults to example.org' do
    request '/'
    last_request.env['SERVER_NAME'].must_equal 'example.org'
  end

  it 'yields the response to a given block' do
    request '/' do |response|
      response.must_be :ok?
    end
  end

  it 'supports sending :params for GET' do
    request '/', params: { 'foo' => 'bar' }
    last_request.GET['foo'].must_equal 'bar'
  end

  it 'supports sending :query_params for GET' do
    request '/', query_params: { 'foo' => 'bar' }
    last_request.GET['foo'].must_equal 'bar'
  end

  it 'supports sending both :params and :query_params for GET' do
    request '/', query_params: { 'foo' => 'bar' }, params: { 'foo2' => 'bar2' }
    last_request.GET['foo'].must_equal 'bar'
    last_request.GET['foo2'].must_equal 'bar2'
  end

  it 'supports sending :params for POST' do
    request '/', method: :post, params: { 'foo' => 'bar' }
    last_request.POST['foo'].must_equal 'bar'
  end

  it 'does not use multipart input for :params for POST by default' do
    request '/', method: :post, params: { 'foo' => 'bar' }
    last_request.POST['foo'].must_equal 'bar'
    last_request.env['rack.input'].rewind
    last_request.env['rack.input'].read.must_equal 'foo=bar'
  end

  it 'supports :multipart when using :params for POST to force multipart input' do
    request '/', method: :post, params: { 'foo' => 'bar' }, multipart: true
    last_request.POST['foo'].must_equal 'bar'
    last_request.env['rack.input'].rewind
    last_request.env['rack.input'].read.must_include 'content-disposition: form-data; name="foo"'
  end

  it 'supports multipart CONTENT_TYPE when using :params for POST to force multipart input' do
    request '/', method: :post, params: { 'foo' => 'bar' }, 'CONTENT_TYPE'=>'multipart/form-data'
    last_request.POST['foo'].must_equal 'bar'
    last_request.env['rack.input'].rewind
    last_request.env['rack.input'].read.must_include 'content-disposition: form-data; name="foo"'
  end

  it 'supports sending :query_params for POST' do
    request '/', method: :post, query_params: { 'foo' => 'bar' }
    last_request.GET['foo'].must_equal 'bar'
  end

  it 'supports sending both :params and :query_params for POST' do
    request '/', method: :post, query_params: { 'foo' => 'bar' }, params: { 'foo2' => 'bar2' }
    last_request.GET['foo'].must_equal 'bar'
    last_request.POST['foo2'].must_equal 'bar2'
  end

  it "doesn't follow redirects by default" do
    request '/redirect'
    last_response.must_be :redirect?
    last_response.body.must_be_empty
  end

  it 'allows passing :input in for POSTs' do
    request '/', method: :post, input: 'foo'
    last_request.env['rack.input'].read.must_equal 'foo'
  end

  it 'converts method names to a uppercase strings' do
    request '/', method: :put
    last_request.env['REQUEST_METHOD'].must_equal 'PUT'
  end

  it 'prepends a slash to the URI path' do
    request 'foo'
    last_request.env['PATH_INFO'].must_equal '/foo'
  end

  it 'accepts params and builds query strings for GET requests' do
    request '/foo?baz=2', params: { foo: { bar: '1' } }
    last_request.GET.must_equal 'baz' => '2', 'foo' => { 'bar' => '1' }
  end

  it 'parses query strings with repeated variable names correctly' do
    request '/foo?bar=2&bar=3'
    last_request.GET.must_equal 'bar' => '3'
  end

  it 'accepts raw input in params for GET requests' do
    request '/foo?baz=2', params: 'foo[bar]=1'
    last_request.GET.must_equal 'baz' => '2', 'foo' => { 'bar' => '1' }
  end

  it 'does not rewrite a GET query string when :params is not supplied' do
    request '/foo?a=1&b=2&c=3&e=4&d=5+%20'
    last_request.query_string.must_equal 'a=1&b=2&c=3&e=4&d=5+%20'
  end

  it 'does not rewrite a GET query string when :params is empty' do
    request '/foo?a=1&b=2&c=3&e=4&d=5', params: {}
    last_request.query_string.must_equal 'a=1&b=2&c=3&e=4&d=5'
  end

  it 'does not overwrite multiple query string keys' do
    request '/foo?a=1&a=2', params: { bar: 1 }
    last_request.query_string.must_equal 'a=1&a=2&bar=1'
  end

  it 'accepts params and builds url encoded params for POST requests' do
    request '/foo', method: :post, params: { foo: { bar: '1' } }
    last_request.env['rack.input'].read.must_equal 'foo[bar]=1'
  end

  it 'accepts raw input in params for POST requests' do
    request '/foo', method: :post, params: 'foo[bar]=1'
    last_request.env['rack.input'].read.must_equal 'foo[bar]=1'
  end

  it 'supports a Rack::Response' do
    app = lambda do |_env|
      Rack::Response.new('', 200, {})
    end

    session = Rack::Test::Session.new(Rack::MockSession.new(app))
    session.request('/').must_be :ok?
  end

  closeable_body = Class.new do
    def initialize
      @closed = false
    end

    def each
      return if @closed
      yield 'Hello, World!'
    end

    def close
      @closed = true
    end

    def closed?
      @closed
    end
  end

  it "closes response's body when body responds_to?(:close)" do
    body = closeable_body.new

    app = lambda do |_env|
      [200, { 'content-type' => 'text/html', 'content-length' => '13' }, body]
    end

    session = Rack::Test::Session.new(Rack::MockSession.new(app))
    body.closed?.must_equal false
    session.request('/')
    body.closed?.must_equal true
  end

  it "closes response's body after iteration when body responds_to?(:close)" do
    body = nil
    app = lambda do |_env|
      [200, { 'content-type' => 'text/html', 'content-length' => '13' }, body = closeable_body.new]
    end

    session = Rack::Test::Session.new(Rack::MockSession.new(app))
    session.request('/')
    session.last_response.body.must_equal 'Hello, World!'
    body.closed?.must_equal true
  end

  it 'sends the input when input is given' do
    request '/', method: 'POST', input: 'foo'
    last_request.env['rack.input'].read.must_equal 'foo'
  end

  it 'does not send a multipart request when input is given' do
    request '/', method: 'POST', input: 'foo'
    last_request.env['CONTENT_TYPE'].wont_equal 'application/x-www-form-urlencoded'
  end

  it 'uses application/x-www-form-urlencoded as the CONTENT_TYPE for a POST specified with :method' do
    request '/', method: 'POST'
    last_request.env['CONTENT_TYPE'].must_equal 'application/x-www-form-urlencoded'
  end

  it 'uses application/x-www-form-urlencoded as the CONTENT_TYPE for a POST specified with REQUEST_METHOD' do
    request '/', 'REQUEST_METHOD' => 'POST'
    last_request.env['CONTENT_TYPE'].must_equal 'application/x-www-form-urlencoded'
  end

  it 'does not overwrite the CONTENT_TYPE when CONTENT_TYPE is specified in the env' do
    request '/', 'CONTENT_TYPE' => 'application/xml'
    last_request.env['CONTENT_TYPE'].must_equal 'application/xml'
  end

  it 'sets rack.url_scheme to https when the URL is https://' do
    request 'https://example.org/'
    last_request.env['rack.url_scheme'].must_equal 'https'
  end

  it 'sets SERVER_PORT to 443 when the URL is https://' do
    request 'https://example.org/'
    last_request.env['SERVER_PORT'].must_equal '443'
  end

  it 'sets HTTPS to on when the URL is https://' do
    request 'https://example.org/'
    last_request.env['HTTPS'].must_equal 'on'
  end

  it 'sends XMLHttpRequest for the X-Requested-With header if :xhr option is given' do
    request '/', xhr: true
    last_request.env['HTTP_X_REQUESTED_WITH'].must_equal 'XMLHttpRequest'
    last_request.must_be :xhr?
  end
end

describe 'Rack::Test::Session#header' do
  it 'sets a header to be sent with requests' do
    header 'User-Agent', 'Firefox'
    request '/'

    last_request.env['HTTP_USER_AGENT'].must_equal 'Firefox'
  end

  it 'sets a content-type to be sent with requests' do
    header 'content-type', 'application/json'
    request '/'

    last_request.env['CONTENT_TYPE'].must_equal 'application/json'
  end

  it 'sets a Host to be sent with requests' do
    header 'Host', 'www.example.ua'
    request '/'

    last_request.env['HTTP_HOST'].must_equal 'www.example.ua'
  end

  it 'persists across multiple requests' do
    header 'User-Agent', 'Firefox'
    request '/'
    request '/'

    last_request.env['HTTP_USER_AGENT'].must_equal 'Firefox'
  end

  it 'overwrites previously set headers' do
    header 'User-Agent', 'Firefox'
    header 'User-Agent', 'Safari'
    request '/'

    last_request.env['HTTP_USER_AGENT'].must_equal 'Safari'
  end

  it 'can be used to clear a header' do
    header 'User-Agent', 'Firefox'
    header 'User-Agent', nil
    request '/'

    last_request.env.wont_include 'HTTP_USER_AGENT'
  end

  it 'is overridden by headers sent during the request' do
    header 'User-Agent', 'Firefox'
    request '/', 'HTTP_USER_AGENT' => 'Safari'

    last_request.env['HTTP_USER_AGENT'].must_equal 'Safari'
  end
end

describe 'Rack::Test::Session#env' do
  it 'sets the env to be sent with requests' do
    env 'rack.session', csrf: 'token'
    request '/'

    last_request.env['rack.session'].must_equal csrf: 'token'
  end

  it 'persists across multiple requests' do
    env 'rack.session', csrf: 'token'
    request '/'
    request '/'

    last_request.env['rack.session'].must_equal csrf: 'token'
  end

  it 'overwrites previously set envs' do
    env 'rack.session', csrf: 'token'
    env 'rack.session', some: :thing
    request '/'

    last_request.env['rack.session'].must_equal some: :thing
  end

  it 'can be used to clear a env' do
    env 'rack.session', csrf: 'token'
    env 'rack.session', nil
    request '/'

    last_request.env.wont_include 'X_CSRF_TOKEN'
  end

  it 'is overridden by envs sent during the request' do
    env 'rack.session', csrf: 'token'
    request '/', 'rack.session' => { some: :thing }

    last_request.env['rack.session'].must_equal some: :thing
  end
end

describe 'Rack::Test::Session#basic_authorize' do
  it 'sets the HTTP_AUTHORIZATION header' do
    basic_authorize 'bryan', 'secret'
    request '/'

    last_request.env['HTTP_AUTHORIZATION'].must_equal 'Basic YnJ5YW46c2VjcmV0'
  end

  it 'includes the header for subsequent requests' do
    basic_authorize 'bryan', 'secret'
    request '/'
    request '/'

    last_request.env['HTTP_AUTHORIZATION'].must_equal 'Basic YnJ5YW46c2VjcmV0'
  end
end

describe 'Rack::Test::Session#digest_authorize' do
  challenge_data = 'realm="test-realm", qop="auth", nonce="nonsensenonce", opaque="morenonsense"'.freeze
  basic_headers    = { 'content-type' => 'text/html', 'content-length' => '13' }.freeze
  digest_challenge = "Digest #{challenge_data}".freeze
  auth_challenge_headers = { 'WWW-Authenticate' => digest_challenge }.freeze
  cookie_headers = { 'Set-Cookie' => 'digest_auth_session=OZEnmjeekUSW%3D%3D; path=/; HttpOnly' }.freeze

  digest_app = lambda do |_env|
    [401, basic_headers.merge(auth_challenge_headers).merge(cookie_headers), '']
  end

  define_method(:app){digest_app}

  def request
    digest_authorize('test-name', 'test-password')
    super('/')
    last_request
  end

  deprecated 'is defined directly on the session' do
    current_session.digest_authorize('test-name', 'test-password')
    get('/')
    last_request.env['rack-test.digest_auth_retry'].must_equal true
  end

  deprecated 'retries digest requests' do
    request.env['rack-test.digest_auth_retry'].must_equal true
  end

  deprecated 'sends a digest auth header' do
    request.env['HTTP_AUTHORIZATION'].must_include 'Digest realm'
  end

  deprecated 'includes the response based on the username,password and nonce' do
    request.env['HTTP_AUTHORIZATION'].must_include 'response="d773034bdc162b31c50c62764016bd31"'
  end

  deprecated 'includes the challenge headers' do
    request.env['HTTP_AUTHORIZATION'].must_include challenge_data
  end

  deprecated 'includes the username' do
    request.env['HTTP_AUTHORIZATION'].must_include 'username="test-name"'
  end
end

describe 'Rack::Test::Session#follow_redirect!' do
  it 'follows redirects' do
    get '/redirect'
    follow_redirect!

    last_response.wont_be :redirect?
    last_response.body.must_equal "You've been redirected, session {} with options {}"
    last_request.env['HTTP_REFERER'].must_equal 'http://example.org/redirect'
  end

  it 'follows absolute redirects' do
    get '/absolute/redirect'
    last_response.headers['location'].must_equal 'https://www.google.com'
    follow_redirect!
    last_request.env['PATH_INFO'].must_equal '/'
    last_request.env['HTTP_HOST'].must_equal 'www.google.com'
    last_request.env['HTTPS'].must_equal 'on'
  end

  it 'follows nested redirects' do
    get '/nested/redirect'

    last_response.headers['location'].must_equal 'redirected'
    follow_redirect!

    last_response.must_be :ok?
    last_request.env['PATH_INFO'].must_equal '/nested/redirected'
  end

  it 'does not include params when following the redirect' do
    get '/redirect', 'foo' => 'bar'
    follow_redirect!

    last_request.GET.must_be_empty
  end

  it 'includes session when following the redirect' do
    get '/redirect', {}, 'rack.session' => { 'foo' => 'bar' }
    follow_redirect!

    last_response.body.must_include 'session {"foo"=>"bar"}'
  end

  it 'includes session options when following the redirect' do
    get '/redirect', {}, 'rack.session.options' => { 'foo' => 'bar' }
    follow_redirect!

    last_response.body.must_include 'session {} with options {"foo"=>"bar"}'
  end

  it 'raises an error if the last_response is not set' do
    proc do
      follow_redirect!
    end.must_raise(Rack::Test::Error)
  end

  it 'raises an error if the last_response is not a redirect' do
    get '/'

    proc do
      follow_redirect!
    end.must_raise(Rack::Test::Error)
  end

  it 'keeps the original method and params for HTTP 307' do
    post '/redirect?status=307', foo: 'bar'
    follow_redirect!
    last_response.body.must_include 'post'
    last_response.body.must_include 'foo'
    last_response.body.must_include 'bar'
  end
end

describe 'Rack::Test::Session#last_request' do
  it 'returns the most recent request' do
    request '/'
    last_request.env['PATH_INFO'].must_equal '/'
  end

  it 'raises an error if no requests have been issued' do
    proc do
      last_request
    end.must_raise(Rack::Test::Error)
  end
end

describe 'Rack::Test::Session#last_response' do
  it 'returns the most recent response' do
    request '/'
    last_response['content-type'].must_equal 'text/html;charset=utf-8'
  end

  it 'raises an error if no requests have been issued' do
    proc do
      last_response
    end.must_raise(Rack::Test::Error)
  end
end

describe 'Rack::Test::Session#after_request' do
  it 'runs callbacks after each request' do
    ran = false

    rack_mock_session.after_request do
      ran = true
    end

    get '/'
    ran.must_equal true
  end

  it 'runs multiple callbacks' do
    count = 0

    2.times do
      rack_mock_session.after_request do
        count += 1
      end
    end

    get '/'
    count.must_equal 2
  end
end

verb_examples = Module.new do
  extend Minitest::Spec::DSL

  it 'requests the URL using VERB' do
    public_send(verb, '/')

    last_request.env['REQUEST_METHOD'].must_equal verb.to_s.upcase
    last_response.must_be :ok?
  end

  it 'uses the provided env' do
    public_send(verb, '/', {}, 'HTTP_USER_AGENT' => 'Rack::Test')
    last_request.env['HTTP_USER_AGENT'].must_equal 'Rack::Test'
  end

  it 'yields the response to a given block' do
    yielded = false

    public_send(verb, '/') do |response|
      response.must_be :ok?
      yielded = true
    end

    yielded.must_equal true
  end

  it 'sets the HTTP_HOST header with port' do
    public_send(verb, 'http://example.org:8080/uri')
    last_request.env['HTTP_HOST'].must_equal 'example.org:8080'
  end

  it 'sets the HTTP_HOST header without port' do
    public_send(verb, '/uri')
    last_request.env['HTTP_HOST'].must_equal 'example.org'
  end

  it 'sends XMLHttpRequest for the X-Requested-With header' do
    public_send(verb, '/', {}, xhr: true)
    last_request.env['HTTP_X_REQUESTED_WITH'].must_equal 'XMLHttpRequest'
    last_request.must_be :xhr?
  end
end

non_get_verb_examples = Module.new do
  extend Minitest::Spec::DSL

  it 'sets CONTENT_TYPE to application/x-www-form-urlencoded when params are not provided' do
    public_send(verb, '/')
    last_request.env['CONTENT_TYPE'].must_equal 'application/x-www-form-urlencoded'
  end

  it 'sets CONTENT_LENGTH to zero when params are not provided' do
    public_send(verb, '/')
    last_request.env['CONTENT_LENGTH'].must_equal '0'
  end

  it 'sets CONTENT_TYPE to application/x-www-form-urlencoded when params are explicitly set to nil' do
    public_send(verb, '/', nil)
    last_request.env['CONTENT_TYPE'].must_equal 'application/x-www-form-urlencoded'
  end

  it 'sets CONTENT_LENGTH to 0 when params are explicitly set to nil' do
    public_send(verb, '/', nil)
    last_request.env['CONTENT_LENGTH'].must_equal '0'
  end
end

describe 'Rack::Test::Session#get' do
  def verb; :get; end
  include verb_examples

  # This is not actually explicitly stated in the relevant RFCs;
  # https://tools.ietf.org/html/rfc7231#section-3.1.1.5
  # ...but e.g. curl do not set it for GET requests.
  it 'does not set CONTENT_TYPE when params are not provided' do
    get '/'
    last_request.env.wont_include 'CONTENT_TYPE'
  end

  # Quoting from https://tools.ietf.org/html/rfc7230#section-3.3.2:
  #
  #   A user agent SHOULD NOT send a Content-Length header field when
  #   the request message does not contain a payload body and the
  #   method semantics do not anticipate such a body.
  it 'sets CONTENT_LENGTH to zero when params are not provided' do
    get '/'
    last_request.env['CONTENT_LENGTH'].must_equal '0'
  end

  it 'sets CONTENT_TYPE to application/x-www-form-urlencoded when params are explicitly set to nil' do
    get '/', nil
    last_request.env.wont_include 'CONTENT_TYPE'
  end

  it 'sets CONTENT_LENGTH to zero when params are explicitly set to nil' do
    get '/', nil
    last_request.env['CONTENT_LENGTH'].must_equal '0'
  end

  it 'uses the provided params hash' do
    get '/', foo: 'bar'
    last_request.GET.must_equal 'foo' => 'bar'
  end

  it 'sends params with parens in names' do
    get '/', 'foo(1i)' => 'bar'
    last_request.GET['foo(1i)'].must_equal 'bar'
  end

  it 'supports params with encoding sensitive names' do
    get '/', 'foo bar' => 'baz'
    last_request.GET['foo bar'].must_equal 'baz'
  end

  it 'supports params with nested encoding sensitive names' do
    get '/', 'boo' => { 'foo bar' => 'baz' }
    last_request.GET.must_equal 'boo' => { 'foo bar' => 'baz' }
  end

  it 'accepts params in the path' do
    get '/?foo=bar'
    last_request.GET.must_equal 'foo' => 'bar'
  end
end

describe 'Rack::Test::Session#head' do
  def verb; :head; end
  include verb_examples
  include non_get_verb_examples
end

describe 'Rack::Test::Session#post' do
  def verb; :post; end
  include verb_examples
  include non_get_verb_examples

  it 'uses the provided params hash' do
    post '/', foo: 'bar'
    last_request.POST.must_equal 'foo' => 'bar'
  end

  it 'supports params with encoding sensitive names' do
    post '/', 'foo bar' => 'baz'
    last_request.POST['foo bar'].must_equal 'baz'
  end

  it 'uses application/x-www-form-urlencoded as the default CONTENT_TYPE' do
    post '/'
    last_request.env['CONTENT_TYPE'].must_equal 'application/x-www-form-urlencoded'
  end

  it 'sets the CONTENT_LENGTH' do
    post '/', foo: 'bar'
    last_request.env['CONTENT_LENGTH'].must_equal '7'
  end

  it 'accepts a body' do
    post '/', 'Lobsterlicious!'
    last_request.body.read.must_equal 'Lobsterlicious!'
  end

  it 'does not overwrite the CONTENT_TYPE when CONTENT_TYPE is specified in the env' do
    post '/', {}, 'CONTENT_TYPE' => 'application/xml'
    last_request.env['CONTENT_TYPE'].must_equal 'application/xml'
  end
end

describe 'Rack::Test::Session#put' do
  def verb; :put; end
  include verb_examples
  include non_get_verb_examples

  it 'accepts a body' do
    put '/', 'Lobsterlicious!'
    last_request.body.read.must_equal 'Lobsterlicious!'
  end
end

describe 'Rack::Test::Session#patch' do
  def verb; :patch; end
  include verb_examples
  include non_get_verb_examples

  it 'accepts a body' do
    patch '/', 'Lobsterlicious!'
    last_request.body.read.must_equal 'Lobsterlicious!'
  end
end

describe 'Rack::Test::Session#delete' do
  def verb; :delete; end
  include verb_examples
  include non_get_verb_examples

  it 'accepts a body' do
    patch '/', 'Lobsterlicious!'
    last_request.body.read.must_equal 'Lobsterlicious!'
  end

  it 'uses the provided params hash' do
    delete '/', foo: 'bar'
    last_request.GET.must_equal({})
    last_request.POST.must_equal 'foo' => 'bar'
    last_request.body.rewind
    last_request.body.read.must_equal 'foo=bar'
  end

  it 'accepts params in the path' do
    delete '/?foo=bar'
    last_request.GET.must_equal 'foo' => 'bar'
    last_request.POST.must_equal({})
    last_request.body.read.must_equal ''
  end

  it 'accepts a body' do
    delete '/', 'Lobsterlicious!'
    last_request.GET.must_equal({})
    last_request.body.read.must_equal 'Lobsterlicious!'
  end
end

describe 'Rack::Test::Session#options' do
  def verb; :options; end
  include verb_examples
  include non_get_verb_examples
end

describe 'Rack::Test::Session#custom_request' do
  it 'requests the URL using the given' do
    custom_request('link', '/')

    last_request.env['REQUEST_METHOD'].must_equal 'LINK'
    last_response.must_be :ok?
  end

  it 'uses the provided env' do
    custom_request('link', '/', {}, 'HTTP_USER_AGENT' => 'Rack::Test')
    last_request.env['HTTP_USER_AGENT'].must_equal 'Rack::Test'
  end

  it 'yields the response to a given block' do
    yielded = false

    custom_request('link', '/') do |response|
      response.must_be :ok?
      yielded = true
    end

    yielded.must_equal true
  end

  it 'sets the HTTP_HOST header with port' do
    custom_request('link', 'http://example.org:8080/uri')
    last_request.env['HTTP_HOST'].must_equal 'example.org:8080'
  end

  it 'sets the HTTP_HOST header without port' do
    custom_request('link', '/uri')
    last_request.env['HTTP_HOST'].must_equal 'example.org'
  end

  it 'sends XMLHttpRequest for the X-Requested-With header for an XHR' do
    custom_request('link', '/', {}, xhr: true)
    last_request.env['HTTP_X_REQUESTED_WITH'].must_equal 'XMLHttpRequest'
    last_request.must_be :xhr?
  end
end
