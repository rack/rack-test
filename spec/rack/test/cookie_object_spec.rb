require "spec_helper"

describe Rack::Test::Cookie do
  subject(:cookie) { Rack::Test::Cookie.new(cookie_string) }

  let(:cookie_string) { raw_cookie_string }

  let(:raw_cookie_string) {
    [
      "cookie_name=" + CGI.escape(value),
      "domain=" + domain,
      "path=" + path,
      "expires=" + expires,
    ].join("; ")
  }

  let(:http_only_raw_cookie_string) {
    raw_cookie_string + "; HttpOnly"
  }

  let(:http_only_secure_raw_cookie_string) {
    http_only_raw_cookie_string + "; secure"
  }

  let(:value) { "the cookie value" }
  let(:domain) { "www.example.org" }
  let(:path) { "/" }
  let(:expires) { "Mon, 10 Aug 2015 14:40:57 0100" }

  describe "#to_h" do
    let(:cookie_string) { http_only_secure_raw_cookie_string }

    it "returns the cookie value and all options" do
      expect(cookie.to_h).to eq(
                               "value" => value,
                               "domain" => domain,
                               "path" => path,
                               "expires" => expires,
                               "HttpOnly" => true,
                               "secure" => true,
                             )
    end
  end

  describe "#to_hash" do
    it "is an alias for #to_h" do
      expect(cookie.to_hash).to eq(cookie.to_h)
    end
  end

  describe "#http_only?" do
    context "for a non HTTP only cookie" do
      it "returns false" do
        expect(cookie.http_only?).to be(false)
      end
    end

    context "for a HTTP only cookie" do
      let(:cookie_string) { http_only_raw_cookie_string }

      it "returns true" do
        expect(cookie.http_only?).to be(true)
      end
    end
  end
end
