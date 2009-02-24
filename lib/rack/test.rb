require "rack"

module Rack
  module Test
    class Session
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
          options = { :method => verb }
          Rack::MockRequest.env_for(path, options)
        end
    end
  end
end
