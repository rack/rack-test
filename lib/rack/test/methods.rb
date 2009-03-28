require "forwardable"

module Rack
  module Test
    module Methods
      extend Forwardable
      
      def rack_test_session
        @_rack_test_session ||= Rack::Test::Session.new(app)
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
        :authorize,
        # Expose the last request and response
        :last_response,
        :last_request
      ]

      def_delegators :rack_test_session, *METHODS
    end
  end
end
