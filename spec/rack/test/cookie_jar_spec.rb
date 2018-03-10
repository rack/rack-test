require 'spec_helper'

describe Rack::Test::CookieJar do
  subject(:jar) { Rack::Test::CookieJar.new }

  describe '#get_cookie' do
    context 'with a populated jar' do
      let(:cookie_value) { 'foo;abc' }
      let(:cookie_name) { 'a_cookie_name' }

      before do
        jar[cookie_name] = cookie_value
      end

      it 'returns full cookie objects' do
        cookie = jar.get_cookie(cookie_name)
        expect(cookie).to be_a(Rack::Test::Cookie)
      end
    end
  end

  describe '#for' do
    it 'returns the cookie header string delimited by semicolon and a space' do
      jar['a'] = 'b'
      jar['c'] = 'd'

      expect(jar.for(nil)).to eq('a=b; c=d')
    end
  end
end
