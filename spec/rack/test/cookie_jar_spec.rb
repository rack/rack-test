# frozen-string-literal: true

require_relative '../../spec_helper'

describe Rack::Test::CookieJar do
  cookie_value = 'foo;abc'.freeze
  cookie_name = 'a_cookie_name'.freeze

  it 'copies should not share a cookie jar' do
    jar = Rack::Test::CookieJar.new
    jar_dup = jar.dup
    jar_clone = jar.clone

    jar['a'] = 'b'
    jar.to_hash.must_equal 'a' => 'b'
    jar_dup.to_hash.must_be_empty
    jar_clone.to_hash.must_be_empty
  end

  it 'ignores leading dot in domain' do
    jar = Rack::Test::CookieJar.new
    jar << Rack::Test::Cookie.new('a=c; domain=.lithostech.com', URI('https://lithostech.com'))
    jar.get_cookie('a').domain.must_equal 'lithostech.com'
  end

  it '#[] and []= should get and set cookie values' do
    jar = Rack::Test::CookieJar.new
    jar[cookie_name].must_be_nil
    jar[cookie_name] = cookie_value
    jar[cookie_name].must_equal cookie_value
    jar[cookie_name+'a'].must_be_nil
  end

  it '#get_cookie with a populated jar returns full cookie objects' do
    jar = Rack::Test::CookieJar.new
    jar.get_cookie(cookie_name).must_be_nil
    jar[cookie_name] = cookie_value
    jar.get_cookie(cookie_name).must_be_kind_of Rack::Test::Cookie
    jar.get_cookie(cookie_name+'a').must_be_nil
  end

  it '#for returns the cookie header string delimited by semicolon and a space' do
    jar = Rack::Test::CookieJar.new
    jar['a'] = 'b'
    jar['c'] = 'd'

    jar.for(nil).must_equal 'a=b; c=d'
  end

  it '#to_hash returns a hash of cookies' do
    jar = Rack::Test::CookieJar.new
    jar['a'] = 'b'
    jar['c'] = 'd'
    jar.to_hash.must_equal 'a' => 'b', 'c' => 'd'
  end

  it '#merge merges valid raw cookie strings' do
    jar = Rack::Test::CookieJar.new
    jar['a'] = 'b'
    jar.merge('c=d')
    jar.to_hash.must_equal 'a' => 'b', 'c' => 'd'
  end

  it '#merge does not merge invalid raw cookie strings' do
    jar = Rack::Test::CookieJar.new
    jar['a'] = 'b'
    jar.merge('c=d; domain=example.org; secure', URI.parse('/'))
    jar.to_hash.must_equal 'a' => 'b'
  end

  it '#merge ignores empty cookies in cookie strings' do
    jar = Rack::Test::CookieJar.new
    jar.merge('', URI.parse('/'))
    jar.merge("\nc=d")
    jar.to_hash.must_equal 'c' => 'd'
  end

  it '#merge ignores empty cookies in cookie arrays' do
    jar = Rack::Test::CookieJar.new
    jar.merge(['', 'c=d'], URI.parse('/'))
    jar.to_hash.must_equal 'c' => 'd'
  end
end
