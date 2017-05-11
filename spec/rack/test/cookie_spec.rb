require "spec_helper"

describe Rack::Test::Session do

  context "cookies" do
    it "keeps a cookie jar" do
      get "/cookies/show"
      check expect(last_request.cookies).to eq({})

      get "/cookies/set", "value" => "1"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "1" })
    end

    it "doesn't send expired cookies" do
      get "/cookies/set", "value" => "1"
      now = Time.now
      allow(Time).to receive_messages(:now => now + 60)
      get "/cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "cookie path defaults to the uri of the document that was requested" do
      skip "See issue rack-test github issue #50"
      post "/cookies/default-path", "value" => "cookie"
      get "/cookies/default-path"
      expect(last_request.cookies).to eq({ "simple"=>"cookie" })
      get "/cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "escapes cookie values" do
      jar = Rack::Test::CookieJar.new
      jar["value"] = "foo;abc"
      expect(jar["value"]).to eq("foo;abc")
    end

    it "deletes cookies directly from the CookieJar" do
      jar = Rack::Test::CookieJar.new
      jar["abcd"] = "1234"
      expect(jar["abcd"]).to eq("1234")
      jar.delete("abcd")
      expect(jar["abcd"]).to eq(nil)
    end

    it "doesn't send cookies with the wrong domain" do
      get "http://www.example.com/cookies/set", "value" => "1"
      get "http://www.other.example/cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "doesn't send cookies with the wrong path" do
      get "/cookies/set", "value" => "1"
      get "/not-cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "persists cookies across requests that don't return any cookie headers" do
      get "/cookies/set", "value" => "1"
      get "/void"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "1" })
    end

    it "deletes cookies" do
      get "/cookies/set", "value" => "1"
      get "/cookies/delete"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ })
    end

    it "respects cookie domains when no domain is explicitly set" do
      skip "FIXME: www.example.org should not get the first cookie"
      expect(request("http://example.org/cookies/count")).to     have_body("1")
      expect(request("http://www.example.org/cookies/count")).to have_body("1")
      expect(request("http://example.org/cookies/count")).to     have_body("2")
      expect(request("http://www.example.org/cookies/count")).to have_body("2")
    end

    it "treats domains case insensitively" do
      get "http://example.com/cookies/set", "value" => "1"
      get "http://EXAMPLE.COM/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "1" })
    end

    it "treats paths case sensitively" do
      get "/cookies/set", "value" => "1"
      get "/COOKIES/show"
      expect(last_request.cookies).to eq({})
    end

    it "prefers more specific cookies" do
      get "http://example.com/cookies/set",     "value" => "domain"
      get "http://sub.example.com/cookies/set", "value" => "sub"

      get "http://sub.example.com/cookies/show"
      check expect(last_request.cookies).to eq({ "value" => "sub" })

      get "http://example.com/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "domain" })
    end

    it "treats cookie names case insensitively" do
      get "/cookies/set", "value" => "lowercase"
      get "/cookies/set-uppercase", "value" => "UPPERCASE"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "VALUE" => "UPPERCASE" })
    end

    it "defaults the domain to the request domain" do
      get "http://example.com/cookies/set-simple", "value" => "cookie"
      get "http://example.com/cookies/show"
      check expect(last_request.cookies).to eq({ "simple" => "cookie" })

      get "http://other.example/cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "defaults the domain to the request path up to the last slash" do
      get "/cookies/set-simple", "value" => "1"
      get "/not-cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "supports secure cookies" do
      get "https://example.com/cookies/set-secure", "value" => "set"
      get "http://example.com/cookies/show"
      check expect(last_request.cookies).to eq({})

      get "https://example.com/cookies/show"
      expect(last_request.cookies).to eq({ "secure-cookie" => "set" })
      expect(rack_mock_session.cookie_jar['secure-cookie']).to eq('set')
    end

    it "supports secure cookies when enabling SSL via env" do
      get "//example.com/cookies/set-secure", { "value" => "set" }, "HTTPS" => "on"
      get "//example.com/cookies/show", nil, "HTTPS" => "off"
      check expect(last_request.cookies).to eq({})

      get "//example.com/cookies/show", nil, "HTTPS" => "on"
      expect(last_request.cookies).to eq({ "secure-cookie" => "set" })
      expect(rack_mock_session.cookie_jar['secure-cookie']).to eq('set')
    end

    it "keeps separate cookie jars for different domains" do
      get "http://example.com/cookies/set", "value" => "example"
      get "http://example.com/cookies/show"
      check expect(last_request.cookies).to eq({ "value" => "example" })

      get "http://other.example/cookies/set", "value" => "other"
      get "http://other.example/cookies/show"
      check expect(last_request.cookies).to eq({ "value" => "other" })

      get "http://example.com/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "example" })
    end

    it "keeps one cookie jar for domain and its subdomains" do
      get "http://example.org/cookies/subdomain"
      get "http://example.org/cookies/subdomain"
      expect(last_request.cookies).to eq({ "count" => "1" })

      get "http://foo.example.org/cookies/subdomain"
      expect(last_request.cookies).to eq({ "count" => "2" })
    end

    it "allows cookies to be cleared" do
      get "/cookies/set", "value" => "1"
      clear_cookies
      get "/cookies/show"
      expect(last_request.cookies).to eq({})
    end

    it "allow cookies to be set" do
      set_cookie "value=10"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "10" })
    end

    it "allows an array of cookies to be set" do
      set_cookie ["value=10", "foo=bar"]
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "10", "foo" => "bar" })
    end

    it "skips emtpy string cookies" do
      set_cookie "value=10\n\nfoo=bar"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "value" => "10", "foo" => "bar" })
    end

    it "parses multiple cookies properly" do
      get "/cookies/set-multiple"
      get "/cookies/show"
      expect(last_request.cookies).to eq({ "key1" => "value1", "key2" => "value2" })
    end

    it "supports multiple sessions" do
      with_session(:first) do
        get "/cookies/set", "value" => "1"
        get "/cookies/show"
        expect(last_request.cookies).to eq({ "value" => "1" })
      end

      with_session(:second) do
        get "/cookies/show"
        expect(last_request.cookies).to eq({ })
      end
    end

    it "uses :default as the default session name" do
      get "/cookies/set", "value" => "1"
      get "/cookies/show"
      check expect(last_request.cookies).to eq({ "value" => "1" })

      with_session(:default) do
        get "/cookies/show"
        expect(last_request.cookies).to eq({ "value" => "1" })
      end
    end

    it "accepts explicitly provided cookies" do
      request "/cookies/show", :cookie => "value=1"
      expect(last_request.cookies).to eq({ "value" => "1" })
    end
  end
end
