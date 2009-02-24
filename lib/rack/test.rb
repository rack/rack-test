require "uri"
require "rack"

module Rack
  module Test
    class Session
      include Rack::Utils

      attr_reader :last_response
      attr_reader :last_request

      alias_method :response, :last_response
      alias_method :request, :last_request

      def initialize(app)
        @app = app
      end

      def get(path, data=nil, headers=nil)
        request!("GET", path, data, headers)
      end

      private
        def request!(verb, path, data=nil, headers=nil)
          env = env_for(verb, path, data, headers)
          @last_request  = Rack::Request.new(env)
          @last_response = Rack::Response.new(@app.call(env))
        end

        def env_for(verb, path, data, headers)
          uri = URI(path)
          uri.query = param_string(data) if data.is_a?(Hash)
          options = { :method => verb }

          if data.is_a?(Hash)
            headers = data.delete(:headers)
            env     = data.delete(:env)
          end

          options.merge!(headers) if headers
          options.merge!(env)     if env

          Rack::MockRequest.env_for(uri.to_s, options)
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
