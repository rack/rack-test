# frozen-string-literal: true

require_relative '../../spec_helper'
require 'cgi'

describe Rack::Test::Cookie do
  value = 'the cookie value'.freeze
  domain = 'www.example.org'.freeze
  path = '/foo'.freeze
  expires = (Time.now + (24 * 60 * 60)).httpdate
  cookie_string = [
      'cookie_name=' + CGI.escape(value),
      'domain=' + domain,
      'path=' + path,
      'expires=' + expires
    ].join(Rack::Test::CookieJar::DELIMITER).freeze

  define_method(:cookie) do |trailer=''|
    Rack::Test::Cookie.new(cookie_string + trailer)
  end

  it '#to_h returns the cookie value and all options' do
    cookie('; HttpOnly; secure').to_h.must_equal(
      'value' => value,
      'domain' => domain,
      'path' => path,
      'expires' => expires,
      'HttpOnly' => true,
      'secure' => true
    )
  end

  it '#to_hash is an alias for #to_h' do
    cookie.to_hash.must_equal cookie.to_h
  end

  it '#empty? should only be true for empty values' do
    cookie.empty?.must_equal false
    Rack::Test::Cookie.new('value=').empty?.must_equal true
  end

  it '#valid? should consider the given URI scheme for secure cookies' do
    cookie('; secure').valid?(URI.parse('https://www.example.org/')).must_equal true
    cookie('; secure').valid?(URI.parse('httpx://www.example.org/')).must_equal false
    cookie('; secure').valid?(URI.parse('/')).must_equal false
  end

  it '#valid? is indifferent to matching paths' do
    cookie.valid?(URI.parse('https://www.example.org/foo')).must_equal true
    cookie.valid?(URI.parse('https://www.example.org/bar')).must_equal true
  end

  it '#matches? demands matching paths' do
    cookie.matches?(URI.parse('https://www.example.org/foo')).must_equal true
    cookie.matches?(URI.parse('https://www.example.org/bar')).must_equal false
  end

  it '#http_only? for a non HTTP only cookie returns false' do
    cookie.http_only?.must_equal false
  end

  it '#http_only? for an HTTP only cookie returns true' do
    cookie('; HttpOnly').http_only?.must_equal true
  end

  it '#http_only? for an HTTP only cookie returns true' do
    cookie('; httponly').http_only?.must_equal true
  end
end
