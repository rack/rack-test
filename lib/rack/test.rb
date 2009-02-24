require "rubygems"
require "uri"
require "rack"

module Rack
  module Test
    class Session
      include Rack::Utils

      attr_reader :last_response
      attr_reader :last_request

      alias_method :response, :last_response

      def initialize(app)
        raise ArgumentError unless app.respond_to?(:call)

        @app = app
      end

      def get(path, params = {}, env = {})
        env = env_for(path, env.merge(:method => "GET", :params => params))
        request(path, env)
      end

      def post(path, params = {}, env = {})
        env = env_for(path, env.merge(:method => "POST", :params => params))
        request(path, env)
      end

      def request(uri, env = {})
        env["REQUEST_METHOD"] ||= "GET"

        @last_request  = Rack::Request.new(env)
        @last_response = Rack::Response.new(@app.call(env))

        yield @last_response if block_given?
      end

    private

      def env_for(path, env)
        uri = URI(path)

        if (env[:method] == "POST" || env["REQUEST_METHOD"] == "POST")
          env["Content-Type"] = "application/x-www-form-urlencoded"

          params = env.delete(:params)

          if params.is_a?(Hash)
            env[:input] = param_string(params)
          else
            env[:input] = params
          end
        end

        if env[:params]
          uri.query = param_string(env.delete(:params))
        end

        Rack::MockRequest.env_for(uri.to_s, env)
      end

      def param_string(value, prefix = nil)
        case value
        when Array
          value.map { |v|
            param_string(v, "#{prefix}[]")
          } * "&"
        when Hash
          value.map { |k, v|
            param_string(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          } * "&"
        else
          "#{prefix}=#{escape(value)}"
        end
      end

    end
  end
end
