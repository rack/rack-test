require 'spec_helper'

describe Rack::Test::Session do
  describe 'initialization' do
    it 'supports being initialized with a Rack::MockSession app' do
      session = Rack::Test::Session.new(Rack::MockSession.new(app))
      expect(session.request('/')).to be_ok
    end

    it 'supports being initialized with an app' do
      session = Rack::Test::Session.new(app)
      expect(session.request('/')).to be_ok
    end
  end

  describe '#request' do
    it 'requests the URI using GET by default' do
      request '/'
      expect(last_request).to be_get
      expect(last_response).to be_ok
    end

    it 'returns a response' do
      expect(request('/')).to be_ok
    end

    it 'uses the provided env' do
      request '/', 'X-Foo' => 'bar'
      expect(last_request.env['X-Foo']).to eq('bar')
    end

    it 'allows HTTP_HOST to be set' do
      request '/', 'HTTP_HOST' => 'www.example.ua'
      expect(last_request.env['HTTP_HOST']).to eq('www.example.ua')
    end

    it 'sets HTTP_HOST with port for non-default ports' do
      request 'http://foo.com:8080'
      expect(last_request.env['HTTP_HOST']).to eq('foo.com:8080')
      request 'https://foo.com:8443'
      expect(last_request.env['HTTP_HOST']).to eq('foo.com:8443')
    end

    it 'sets HTTP_HOST without port for default ports' do
      request 'http://foo.com'
      expect(last_request.env['HTTP_HOST']).to eq('foo.com')
      request 'http://foo.com:80'
      expect(last_request.env['HTTP_HOST']).to eq('foo.com')
      request 'https://foo.com:443'
      expect(last_request.env['HTTP_HOST']).to eq('foo.com')
    end

    it 'defaults to GET' do
      request '/'
      expect(last_request.env['REQUEST_METHOD']).to eq('GET')
    end

    it 'defaults the REMOTE_ADDR to 127.0.0.1' do
      request '/'
      expect(last_request.env['REMOTE_ADDR']).to eq('127.0.0.1')
    end

    it 'sets rack.test to true in the env' do
      request '/'
      expect(last_request.env['rack.test']).to eq(true)
    end

    it 'defaults to port 80' do
      request '/'
      expect(last_request.env['SERVER_PORT']).to eq('80')
    end

    it 'defaults to example.org' do
      request '/'
      expect(last_request.env['SERVER_NAME']).to eq('example.org')
    end

    it 'yields the response to a given block' do
      request '/' do |response|
        expect(response).to be_ok
      end
    end

    it 'supports sending :params' do
      request '/', params: { 'foo' => 'bar' }
      expect(last_request.GET['foo']).to eq('bar')
    end

    it "doesn't follow redirects by default" do
      request '/redirect'
      expect(last_response).to be_redirect
      expect(last_response.body).to be_empty
    end

    it 'allows passing :input in for POSTs' do
      request '/', method: :post, input: 'foo'
      expect(last_request.env['rack.input'].read).to eq('foo')
    end

    it 'converts method names to a uppercase strings' do
      request '/', method: :put
      expect(last_request.env['REQUEST_METHOD']).to eq('PUT')
    end

    it 'prepends a slash to the URI path' do
      request 'foo'
      expect(last_request.env['PATH_INFO']).to eq('/foo')
    end

    it 'accepts params and builds query strings for GET requests' do
      request '/foo?baz=2', params: { foo: { bar: '1' } }
      expect(last_request.GET).to eq('baz' => '2', 'foo' => { 'bar' => '1' })
    end

    it 'parses query strings with repeated variable names correctly' do
      request '/foo?bar=2&bar=3'
      expect(last_request.GET).to eq('bar' => '3')
    end

    it 'accepts raw input in params for GET requests' do
      request '/foo?baz=2', params: 'foo[bar]=1'
      expect(last_request.GET).to eq('baz' => '2', 'foo' => { 'bar' => '1' })
    end

    it 'does not rewrite a GET query string when :params is not supplied' do
      request '/foo?a=1&b=2&c=3&e=4&d=5+%20'
      expect(last_request.query_string).to eq('a=1&b=2&c=3&e=4&d=5+%20')
    end

    it 'does not rewrite a GET query string when :params is empty' do
      request '/foo?a=1&b=2&c=3&e=4&d=5', params: {}
      expect(last_request.query_string).to eq('a=1&b=2&c=3&e=4&d=5')
    end

    it 'does not overwrite multiple query string keys' do
      request '/foo?a=1&a=2', params: { bar: 1 }
      expect(last_request.query_string).to eq('a=1&a=2&bar=1')
    end

    it 'accepts params and builds url encoded params for POST requests' do
      request '/foo', method: :post, params: { foo: { bar: '1' } }
      expect(last_request.env['rack.input'].read).to eq('foo[bar]=1')
    end

    it 'accepts raw input in params for POST requests' do
      request '/foo', method: :post, params: 'foo[bar]=1'
      expect(last_request.env['rack.input'].read).to eq('foo[bar]=1')
    end

    context 'when the response body responds_to?(:close)' do
      class CloseableBody
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
      end

      it "closes response's body" do
        body = CloseableBody.new
        expect(body).to receive(:close)

        app = lambda do |_env|
          [200, { 'Content-Type' => 'text/html', 'Content-Length' => '13' }, body]
        end

        session = Rack::Test::Session.new(Rack::MockSession.new(app))
        session.request('/')
      end

      it "closes response's body after iteration" do
        app = lambda do |_env|
          [200, { 'Content-Type' => 'text/html', 'Content-Length' => '13' }, CloseableBody.new]
        end

        session = Rack::Test::Session.new(Rack::MockSession.new(app))
        session.request('/')
        expect(session.last_response.body).to eq('Hello, World!')
      end
    end

    context 'when input is given' do
      it 'sends the input' do
        request '/', method: 'POST', input: 'foo'
        expect(last_request.env['rack.input'].read).to eq('foo')
      end

      it 'does not send a multipart request' do
        request '/', method: 'POST', input: 'foo'
        expect(last_request.env['CONTENT_TYPE']).not_to eq('application/x-www-form-urlencoded')
      end
    end

    context 'for a POST specified with :method' do
      it 'uses application/x-www-form-urlencoded as the CONTENT_TYPE' do
        request '/', method: 'POST'
        expect(last_request.env['CONTENT_TYPE']).to eq('application/x-www-form-urlencoded')
      end
    end

    context 'for a POST specified with REQUEST_METHOD' do
      it 'uses application/x-www-form-urlencoded as the CONTENT_TYPE' do
        request '/', 'REQUEST_METHOD' => 'POST'
        expect(last_request.env['CONTENT_TYPE']).to eq('application/x-www-form-urlencoded')
      end
    end

    context 'when CONTENT_TYPE is specified in the env' do
      it 'does not overwrite the CONTENT_TYPE' do
        request '/', 'CONTENT_TYPE' => 'application/xml'
        expect(last_request.env['CONTENT_TYPE']).to eq('application/xml')
      end
    end

    context 'when the URL is https://' do
      it 'sets rack.url_scheme to https' do
        get 'https://example.org/'
        expect(last_request.env['rack.url_scheme']).to eq('https')
      end

      it 'sets SERVER_PORT to 443' do
        get 'https://example.org/'
        expect(last_request.env['SERVER_PORT']).to eq('443')
      end

      it 'sets HTTPS to on' do
        get 'https://example.org/'
        expect(last_request.env['HTTPS']).to eq('on')
      end
    end

    context 'for a XHR' do
      it 'sends XMLHttpRequest for the X-Requested-With header' do
        request '/', xhr: true
        expect(last_request.env['HTTP_X_REQUESTED_WITH']).to eq('XMLHttpRequest')
        expect(last_request).to be_xhr
      end
    end
  end

  describe '#header' do
    it 'sets a header to be sent with requests' do
      header 'User-Agent', 'Firefox'
      request '/'

      expect(last_request.env['HTTP_USER_AGENT']).to eq('Firefox')
    end

    it 'sets a Content-Type to be sent with requests' do
      header 'Content-Type', 'application/json'
      request '/'

      expect(last_request.env['CONTENT_TYPE']).to eq('application/json')
    end

    it 'sets a Host to be sent with requests' do
      header 'Host', 'www.example.ua'
      request '/'

      expect(last_request.env['HTTP_HOST']).to eq('www.example.ua')
    end

    it 'persists across multiple requests' do
      header 'User-Agent', 'Firefox'
      request '/'
      request '/'

      expect(last_request.env['HTTP_USER_AGENT']).to eq('Firefox')
    end

    it 'overwrites previously set headers' do
      header 'User-Agent', 'Firefox'
      header 'User-Agent', 'Safari'
      request '/'

      expect(last_request.env['HTTP_USER_AGENT']).to eq('Safari')
    end

    it 'can be used to clear a header' do
      header 'User-Agent', 'Firefox'
      header 'User-Agent', nil
      request '/'

      expect(last_request.env).not_to have_key('HTTP_USER_AGENT')
    end

    it 'is overridden by headers sent during the request' do
      header 'User-Agent', 'Firefox'
      request '/', 'HTTP_USER_AGENT' => 'Safari'

      expect(last_request.env['HTTP_USER_AGENT']).to eq('Safari')
    end
  end

  describe '#env' do
    it 'sets the env to be sent with requests' do
      env 'rack.session', csrf: 'token'
      request '/'

      expect(last_request.env['rack.session']).to eq(csrf: 'token')
    end

    it 'persists across multiple requests' do
      env 'rack.session', csrf: 'token'
      request '/'
      request '/'

      expect(last_request.env['rack.session']).to eq(csrf: 'token')
    end

    it 'overwrites previously set envs' do
      env 'rack.session', csrf: 'token'
      env 'rack.session', some: :thing
      request '/'

      expect(last_request.env['rack.session']).to eq(some: :thing)
    end

    it 'can be used to clear a env' do
      env 'rack.session', csrf: 'token'
      env 'rack.session', nil
      request '/'

      expect(last_request.env).not_to have_key('X_CSRF_TOKEN')
    end

    it 'is overridden by envs sent during the request' do
      env 'rack.session', csrf: 'token'
      request '/', 'rack.session' => { some: :thing }

      expect(last_request.env['rack.session']).to eq(some: :thing)
    end
  end

  describe '#basic_authorize' do
    it 'sets the HTTP_AUTHORIZATION header' do
      authorize 'bryan', 'secret'
      request '/'

      expect(last_request.env['HTTP_AUTHORIZATION']).to eq('Basic YnJ5YW46c2VjcmV0')
    end

    it 'includes the header for subsequent requests' do
      basic_authorize 'bryan', 'secret'
      request '/'
      request '/'

      expect(last_request.env['HTTP_AUTHORIZATION']).to eq('Basic YnJ5YW46c2VjcmV0')
    end
  end

  describe 'follow_redirect!' do
    it 'follows redirects' do
      get '/redirect'
      follow_redirect!

      expect(last_response).not_to be_redirect
      expect(last_response.body).to eq("You've been redirected, session {}")
      expect(last_request.env['HTTP_REFERER']).to eql('http://example.org/redirect')
    end

    it 'follows nested redirects' do
      get '/nested/redirect'

      expect(last_response.headers['location']).to be == 'redirected'
      follow_redirect!

      expect(last_response).to be_ok
      expect(last_request.env['PATH_INFO']).to eq('/nested/redirected')
    end

    it 'does not include params when following the redirect' do
      get '/redirect', 'foo' => 'bar'
      follow_redirect!

      expect(last_request.GET).to eq({})
    end

    it 'includes session when following the redirect' do
      get '/redirect', {}, 'rack.session' => { 'foo' => 'bar' }
      follow_redirect!

      expect(last_response.body).to include('session {"foo"=>"bar"}')
    end

    it 'raises an error if the last_response is not set' do
      expect do
        follow_redirect!
      end.to raise_error(Rack::Test::Error)
    end

    it 'raises an error if the last_response is not a redirect' do
      get '/'

      expect do
        follow_redirect!
      end.to raise_error(Rack::Test::Error)
    end

    context 'for HTTP 307' do
      it 'keeps the original method' do
        post '/redirect?status=307', foo: 'bar'
        follow_redirect!
        expect(last_response.body).to include('post')
        expect(last_response.body).to include('foo')
        expect(last_response.body).to include('bar')
      end
    end
  end

  describe '#last_request' do
    it 'returns the most recent request' do
      request '/'
      expect(last_request.env['PATH_INFO']).to eq('/')
    end

    it 'raises an error if no requests have been issued' do
      expect do
        last_request
      end.to raise_error(Rack::Test::Error)
    end
  end

  describe '#last_response' do
    it 'returns the most recent response' do
      request '/'
      expect(last_response['Content-Type']).to eq('text/html;charset=utf-8')
    end

    it 'raises an error if no requests have been issued', focus: true do
      expect do
        last_response
      end.to raise_error(Rack::Test::Error)
    end
  end

  describe 'after_request' do
    it 'runs callbacks after each request' do
      ran = false

      rack_mock_session.after_request do
        ran = true
      end

      get '/'
      expect(ran).to eq(true)
    end

    it 'runs multiple callbacks' do
      count = 0

      2.times do
        rack_mock_session.after_request do
          count += 1
        end
      end

      get '/'
      expect(count).to eq(2)
    end
  end

  shared_examples_for 'any #verb methods' do |verb|
    it 'requests the URL using VERB' do
      public_send(verb, '/')

      check expect(last_request.env['REQUEST_METHOD']).to eq(verb.to_s.upcase)
      expect(last_response).to be_ok
    end

    it 'uses the provided env' do
      public_send(verb, '/', {}, 'HTTP_USER_AGENT' => 'Rack::Test')
      expect(last_request.env['HTTP_USER_AGENT']).to eq('Rack::Test')
    end

    context 'when params are not provided', unless: verb == :get do
      it 'sets CONTENT_TYPE to application/x-www-form-urlencoded' do
        public_send(verb, '/')
        expect(last_request.env['CONTENT_TYPE']).to eq 'application/x-www-form-urlencoded'
      end

      it 'sets CONTENT_LENGTH to zero' do
        public_send(verb, '/')
        expect(last_request.env['CONTENT_LENGTH']).to eq '0'
      end
    end

    context 'when params are explicitly set to nil', unless: verb == :get do
      it 'sets CONTENT_TYPE to application/x-www-form-urlencoded' do
        public_send(verb, '/', nil)
        expect(last_request.env['CONTENT_TYPE']).to eq 'application/x-www-form-urlencoded'
      end

      it 'sets CONTENT_LENGTH to 0' do
        public_send(verb, '/')
        expect(last_request.env['CONTENT_LENGTH']).to eq '0'
      end
    end

    it 'yields the response to a given block' do
      yielded = false

      public_send(verb, '/') do |response|
        expect(response).to be_ok
        yielded = true
      end

      expect(yielded).to be_truthy
    end

    it 'sets the HTTP_HOST header with port' do
      public_send(verb, 'http://example.org:8080/uri')
      expect(last_request.env['HTTP_HOST']).to eq('example.org:8080')
    end

    it 'sets the HTTP_HOST header without port' do
      public_send(verb, '/uri')
      expect(last_request.env['HTTP_HOST']).to eq('example.org')
    end

    context 'for a XHR' do
      it 'sends XMLHttpRequest for the X-Requested-With header' do
        public_send(verb, '/', {}, xhr: true)
        expect(last_request.env['HTTP_X_REQUESTED_WITH']).to eq('XMLHttpRequest')
        expect(last_request).to be_xhr
      end
    end
  end

  describe '#get' do
    it_should_behave_like 'any #verb methods', :get

    context 'when params are not provided' do
      # This is not actually explicitly stated in the relevant RFCs;
      # https://tools.ietf.org/html/rfc7231#section-3.1.1.5
      # ...but e.g. curl do not set it for GET requests.
      it 'does not set CONTENT_TYPE' do
        get '/'
        expect(last_request.env.key?('CONTENT_TYPE')).to eq false
      end

      # Quoting from https://tools.ietf.org/html/rfc7230#section-3.3.2:
      #
      #   A user agent SHOULD NOT send a Content-Length header field when
      #   the request message does not contain a payload body and the
      #   method semantics do not anticipate such a body.
      #
      # _However_, something causes CONTENT_LENGTH to always be present.
      # Even when we don't set it ourselves. It could be
      # Rack::ContentLength that is playing tricks with us:
      # https://github.com/rack/rack/blob/master/lib/rack/content_length.rb
      it 'sets CONTENT_LENGTH to zero' do
        get '/'
        expect(last_request.env['CONTENT_LENGTH']).to eq '0'
      end
    end

    context 'when params are explicitly set to nil' do
      it 'sets CONTENT_TYPE to application/x-www-form-urlencoded' do
        get '/', nil
        expect(last_request.env.key?('CONTENT_TYPE')).to eq false
      end

      it 'sets CONTENT_LENGTH to zero' do
        get '/', nil
        expect(last_request.env['CONTENT_LENGTH']).to eq '0'
      end
    end

    it 'uses the provided params hash' do
      get '/', foo: 'bar'
      expect(last_request.GET).to eq('foo' => 'bar')
    end

    it 'sends params with parens in names' do
      get '/', 'foo(1i)' => 'bar'
      expect(last_request.GET['foo(1i)']).to eq('bar')
    end

    it 'supports params with encoding sensitive names' do
      get '/', 'foo bar' => 'baz'
      expect(last_request.GET['foo bar']).to eq('baz')
    end

    it 'supports params with nested encoding sensitive names' do
      get '/', 'boo' => { 'foo bar' => 'baz' }
      expect(last_request.GET).to eq('boo' => { 'foo bar' => 'baz' })
    end

    it 'accepts params in the path' do
      get '/?foo=bar'
      expect(last_request.GET).to eq('foo' => 'bar')
    end
  end

  describe '#head' do
    it_should_behave_like 'any #verb methods', :head
  end

  describe '#post' do
    it_should_behave_like 'any #verb methods', :post

    it 'uses the provided params hash' do
      post '/', foo: 'bar'
      expect(last_request.POST).to eq('foo' => 'bar')
    end

    it 'supports params with encoding sensitive names' do
      post '/', 'foo bar' => 'baz'
      expect(last_request.POST['foo bar']).to eq('baz')
    end

    it 'uses application/x-www-form-urlencoded as the default CONTENT_TYPE' do
      post '/'
      expect(last_request.env['CONTENT_TYPE']).to eq('application/x-www-form-urlencoded')
    end

    # NB: This is never set in _our code_, but is added automatically
    # (presumably by Rack::ContentLength)
    it 'sets the CONTENT_LENGTH' do
      post '/', foo: 'bar'
      expect(last_request.env['CONTENT_LENGTH']).to eq('7')
    end

    it 'accepts a body' do
      post '/', 'Lobsterlicious!'
      expect(last_request.body.read).to eq('Lobsterlicious!')
    end

    context 'when CONTENT_TYPE is specified in the env' do
      it 'does not overwrite the CONTENT_TYPE' do
        post '/', {}, 'CONTENT_TYPE' => 'application/xml'
        expect(last_request.env['CONTENT_TYPE']).to eq('application/xml')
      end
    end
  end

  describe '#put' do
    it_should_behave_like 'any #verb methods', :put

    it 'accepts a body' do
      put '/', 'Lobsterlicious!'
      expect(last_request.body.read).to eq('Lobsterlicious!')
    end
  end

  describe '#patch' do
    it_should_behave_like 'any #verb methods', :patch

    it 'accepts a body' do
      patch '/', 'Lobsterlicious!'
      expect(last_request.body.read).to eq('Lobsterlicious!')
    end
  end

  describe '#delete' do
    it_should_behave_like 'any #verb methods', :delete

    it 'uses the provided params hash' do
      delete '/', foo: 'bar'
      expect(last_request.GET).to eq({})
      expect(last_request.POST).to eq('foo' => 'bar')
      expect(last_request.body.read).to eq('foo=bar')
    end

    it 'accepts params in the path' do
      delete '/?foo=bar'
      expect(last_request.GET).to eq('foo' => 'bar')
      expect(last_request.POST).to eq({})
      expect(last_request.body.read).to eq('')
    end

    it 'accepts a body' do
      delete '/', 'Lobsterlicious!'
      expect(last_request.GET).to eq({})
      expect(last_request.body.read).to eq('Lobsterlicious!')
    end
  end

  describe '#options' do
    it_should_behave_like 'any #verb methods', :options
  end

  describe '#custom_request' do
    it 'requests the URL using the given' do
      custom_request('link', '/')

      check expect(last_request.env['REQUEST_METHOD']).to eq('LINK')
      expect(last_response).to be_ok
    end

    it 'uses the provided env' do
      custom_request('link', '/', {}, 'HTTP_USER_AGENT' => 'Rack::Test')
      expect(last_request.env['HTTP_USER_AGENT']).to eq('Rack::Test')
    end

    it 'yields the response to a given block' do
      yielded = false

      custom_request('link', '/') do |response|
        expect(response).to be_ok
        yielded = true
      end

      expect(yielded).to be_truthy
    end

    it 'sets the HTTP_HOST header with port' do
      custom_request('link', 'http://example.org:8080/uri')
      expect(last_request.env['HTTP_HOST']).to eq('example.org:8080')
    end

    it 'sets the HTTP_HOST header without port' do
      custom_request('link', '/uri')
      expect(last_request.env['HTTP_HOST']).to eq('example.org')
    end

    context 'for a XHR' do
      it 'sends XMLHttpRequest for the X-Requested-With header' do
        custom_request('link', '/', {}, xhr: true)
        expect(last_request.env['HTTP_X_REQUESTED_WITH']).to eq('XMLHttpRequest')
        expect(last_request).to be_xhr
      end
    end
  end
end
