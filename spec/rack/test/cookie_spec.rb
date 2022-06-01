# frozen-string-literal: true

require_relative '../../spec_helper'

describe "Rack::Test::Session" do
  it 'keeps a cookie jar' do
    get '/cookies/show'
    last_request.cookies.must_equal({})

    get '/cookies/set', 'value' => '1'
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '1'
  end

  it "doesn't send expired cookies" do
    get '/cookies/set', 'value' => '1'
    cookie = rack_mock_session.cookie_jar.instance_variable_get(:@cookies).first
    def cookie.expired?; true end
    get '/cookies/show'
    last_request.cookies.must_equal({})
  end

  it 'cookie path defaults to the directory of the document that was requested' do
    post '/cookies/default-path', 'value' => 'cookie'
    get '/cookies/default-path'
    last_request.cookies.must_equal 'simple' => 'cookie'
    get '/cookies/default-path/sub'
    last_request.cookies.must_equal 'simple' => 'cookie'
    get '/'
    last_request.cookies.must_equal({})
    get '/COOKIES/show'
    last_request.cookies.must_equal({})
  end

  it 'uses the first "path" when multiple paths are defined' do
    cookie_string = [
      '/',
      'csrf_id=ABC123',
      'path=/, _github_ses=ABC123',
      'path=/',
      'expires=Wed, 01 Jan 2020 08:00:00 GMT',
      'HttpOnly'
    ].join(Rack::Test::CookieJar::DELIMITER)
    cookie = Rack::Test::Cookie.new(cookie_string)
    cookie.path.must_equal '/'
  end

  it 'uses the single "path" when only one path is defined' do
    cookie_string = [
      '/',
      'csrf_id=ABC123',
      'path=/',
      'expires=Wed, 01 Jan 2020 08:00:00 GMT',
      'HttpOnly'
    ].join(Rack::Test::CookieJar::DELIMITER)
    cookie = Rack::Test::Cookie.new(cookie_string)
    cookie.path.must_equal '/'
  end

  it 'escapes cookie values' do
    jar = Rack::Test::CookieJar.new
    jar['value'] = 'foo;abc'
    # Looks like it is not escaping, but actually escapes and unescapes,
    # otherwise abc would be treated as an attribute and not part of the value.
    jar['value'].must_equal 'foo;abc'
  end

  it 'deletes cookies directly from the CookieJar' do
    jar = Rack::Test::CookieJar.new
    jar['abcd'] = '1234'
    jar['abcd'].must_equal '1234'
    jar.delete('abcd')
    jar['abcd'].must_be_nil
  end

  it 'allow symbol access' do
    jar = Rack::Test::CookieJar.new
    jar['value'] = 'foo;abc'
    jar[:value].must_equal 'foo;abc'
  end

  it "doesn't send cookies with the wrong domain" do
    get 'http://www.example.com/cookies/set', 'value' => '1'
    get 'http://www.other.example/cookies/show'
    last_request.cookies.must_equal({})
  end

  it "doesn't send cookies with the wrong path" do
    get '/cookies/set', 'value' => '1'
    get '/not-cookies/show'
    last_request.cookies.must_equal({})
  end

  it "persists cookies across requests that don't return any cookie headers" do
    get '/cookies/set', 'value' => '1'
    get '/void'
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '1'
  end

  it 'deletes cookies' do
    get '/cookies/set', 'value' => '1'
    get '/cookies/delete'
    get '/cookies/show'
    last_request.cookies.must_equal({})
  end

  it 'respects cookie domains when no domain is explicitly set' do
    request('http://example.org/cookies/count').body.must_equal '1'
    request('http://www.example.org/cookies/count').body.must_equal '1'
    request('http://example.org/cookies/count').body.must_equal '2'
    request('http://www.example.org/cookies/count').body.must_equal '2'
  end

  it 'treats domains case insensitively' do
    get 'http://example.com/cookies/set', 'value' => '1'
    get 'http://EXAMPLE.COM/cookies/show'
    last_request.cookies.must_equal 'value' => '1'
  end

  it 'treats paths case sensitively' do
    get '/cookies/set', 'value' => '1'
    get '/COOKIES/show'
    last_request.cookies.must_equal({})
  end

  it 'prefers more specific cookies' do
    get 'http://example.com/cookies/set',     'value' => 'domain'
    get 'http://sub.example.com/cookies/set', 'value' => 'sub'

    get 'http://sub.example.com/cookies/show'
    last_request.cookies.must_equal 'value' => 'sub'

    get 'http://example.com/cookies/show'
    last_request.cookies.must_equal 'value' => 'domain'
  end

  it 'treats cookie names case insensitively' do
    get '/cookies/set', 'value' => 'lowercase'
    get '/cookies/set-uppercase', 'value' => 'UPPERCASE'
    get '/cookies/show'
    last_request.cookies.must_equal 'VALUE' => 'UPPERCASE'
  end

  it 'defaults the domain to the request domain' do
    get 'http://example.com/cookies/set-simple', 'value' => 'cookie'
    get 'http://example.com/cookies/show'
    last_request.cookies.must_equal 'simple' => 'cookie'

    get 'http://other.example/cookies/show'
    last_request.cookies.must_equal({})
  end

  it 'defaults the domain to the request path up to the last slash' do
    get '/cookies/set-simple', 'value' => '1'
    get '/not-cookies/show'
    last_request.cookies.must_equal({})
  end

  it 'supports secure cookies' do
    get 'https://example.com/cookies/set-secure', 'value' => 'set'
    get 'http://example.com/cookies/show'
    last_request.cookies.must_equal({})

    get 'https://example.com/cookies/show'
    last_request.cookies.must_equal('secure-cookie' => 'set')
    rack_mock_session.cookie_jar['secure-cookie'].must_equal 'set'
  end

  it 'supports secure cookies when enabling SSL via env' do
    get '//example.com/cookies/set-secure', { 'value' => 'set' }, 'HTTPS' => 'on'
    get '//example.com/cookies/show', nil, 'HTTPS' => 'off'
    last_request.cookies.must_equal({})

    get '//example.com/cookies/show', nil, 'HTTPS' => 'on'
    last_request.cookies.must_equal('secure-cookie' => 'set')
    rack_mock_session.cookie_jar['secure-cookie'].must_equal 'set'
  end

  it 'keeps separate cookie jars for different domains' do
    get 'http://example.com/cookies/set', 'value' => 'example'
    get 'http://example.com/cookies/show'
    last_request.cookies.must_equal 'value' => 'example'

    get 'http://other.example/cookies/set', 'value' => 'other'
    get 'http://other.example/cookies/show'
    last_request.cookies.must_equal 'value' => 'other'

    get 'http://example.com/cookies/show'
    last_request.cookies.must_equal 'value' => 'example'
  end

  it 'keeps one cookie jar for domain and its subdomains' do
    get 'http://example.org/cookies/subdomain'
    get 'http://example.org/cookies/subdomain'
    last_request.cookies.must_equal 'count' => '1'

    get 'http://foo.example.org/cookies/subdomain'
    last_request.cookies.must_equal 'count' => '2'
  end

  it 'allows cookies to be cleared' do
    get '/cookies/set', 'value' => '1'
    clear_cookies
    get '/cookies/show'
    last_request.cookies.must_equal({})
  end

  it 'allow cookies to be set' do
    set_cookie 'value=10'
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '10'
  end

  it 'allows an array of cookies to be set' do
    set_cookie ['value=10', 'foo=bar']
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '10', 'foo' => 'bar'
  end

  it 'skips emtpy string cookies' do
    set_cookie "value=10\n\nfoo=bar"
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '10', 'foo' => 'bar'
  end

  it 'parses multiple cookies properly' do
    get '/cookies/set-multiple'
    get '/cookies/show'
    last_request.cookies.must_equal 'key1' => 'value1', 'key2' => 'value2'
  end

  it 'supports multiple sessions' do
    with_session(:first) do
      get '/cookies/set', 'value' => '1'
      get '/cookies/show'
      last_request.cookies.must_equal 'value' => '1'
    end

    with_session(:second) do
      get '/cookies/show'
      last_request.cookies.must_equal({})
    end
  end

  it 'uses :default as the default session name' do
    get '/cookies/set', 'value' => '1'
    get '/cookies/show'
    last_request.cookies.must_equal 'value' => '1'

    with_session(:default) do
      get '/cookies/show'
      last_request.cookies.must_equal 'value' => '1'
    end
  end

  it 'accepts explicitly provided cookies' do
    request '/cookies/show', cookie: 'value=1'
    last_request.cookies.must_equal 'value' => '1'
  end
end
