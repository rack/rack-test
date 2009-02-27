require "rubygems"
require "uri"
require "rack"

require File.dirname(__FILE__) + "/test/cookie_jar"
require File.dirname(__FILE__) + "/test/utils"

module Rack
  module Test
    
    class Session
      include Rack::Utils
      include Rack::Test::Utils

      def initialize(app)
        raise ArgumentError unless app.respond_to?(:call)

        @app = app
      end

      [:get, :post, :put, :delete, :head].each do |http_method|
        class_eval <<-SRC
          def #{http_method}(uri, params = {}, env = {})          # def get(uri, params = {}, env = {})
            env = env_for(uri,                                    #   env = env_for(uri,
              env.merge(:method => "#{http_method.to_s.upcase}",  #     env.merge(:method => "GET",
              :params => params))                                 #     :params => params))
            process_request(uri, env)                             #   process_request(uri, env)
          end                                                     # end
        SRC
      end

      def env_for(path, env)
        uri = URI.parse(path)
        uri.host ||= "example.org"

        env = default_env.merge(env)

        if URI::HTTPS === uri
          env.update("HTTPS" => "on")
        end

        if (env[:method] == "POST" || env["REQUEST_METHOD"] == "POST") && !env.has_key?(:input)
          env["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
          env[:input] = params_to_string(env.delete(:params))
        end

        params = env[:params] || {}
        params.update(parse_query(uri.query))
        uri.query = requestify(params)

        if env.has_key?(:cookie)
          # Add the cookies explicitly set by the user
          env["HTTP_COOKIE"] = cookie_jar.merge(uri, env.delete(:cookie)).for(uri)
        else
          env["HTTP_COOKIE"] = cookie_jar.for(uri)
        end

        Rack::MockRequest.env_for(uri.to_s, env)
      end

      def request(uri, env = {})
        env = env_for(uri, env)
        process_request(uri, env)

        yield @last_response if block_given?

        @last_response
      end

      def follow_redirect!
        get(last_response["Location"])
      end

      def last_request
        raise unless @last_request

        @last_request
      end

      def last_response
        raise unless @last_response

        @last_response
      end

      alias_method :response, :last_response

    private

      def cookie_jar
        @cookie_jar || Rack::Test::CookieJar.new
      end

      def process_request(uri, env)
        uri = URI.parse(uri)
        uri.host ||= "example.org"

        @last_request = Rack::Request.new(env)

        status, headers, body = @app.call(@last_request.env)
        @last_response = Rack::Response.new(body, status, headers)
        @cookie_jar = cookie_jar.merge(uri, last_response.headers["Set-Cookie"])

        @last_response
      end

      def default_env
        {
          "rack.test"   => true,
          "REMOTE_ADDR" => "127.0.0.1"
        }
      end

      def params_to_string(params)
        case params
        when Hash then requestify(params)
        when nil  then ""
        else params
        end
      end
      
    end
    
  end
end
