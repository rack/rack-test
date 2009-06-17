require "forwardable"

module Rack
  module Test
    module Methods
      extend Forwardable

      def rack_mock_session(name = :default)
        return Rack::MockSession.new(app) if name.nil?

        @_rack_mock_sessions ||= {}
        @_rack_mock_sessions[name] ||= Rack::MockSession.new(app)
      end

      def rack_test_session(name = :default)
        @_rack_test_sessions ||= {}
        @_rack_test_sessions[name] ||= Rack::Test::Session.new(rack_mock_session(name))
      end

      METHODS = [
        :request,

        # HTTP verbs
        :get,
        :post,
        :put,
        :delete,
        :head,

        # Redirects
        :follow_redirect!,

        # Header-related features
        :header,
        :set_cookie,
        :clear_cookies,
        :authorize,
        :basic_authorize,
        :digest_authorize,

        # Expose the last request and response
        :last_response,
        :last_request
      ]

      def_delegators :rack_test_session, *METHODS
    end
  end
end
