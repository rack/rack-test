require 'forwardable'

module Rack
  module Test
    # This module serves as the primary integration point for using Rack::Test
    # in a testing environment. It depends on an app method being defined in the
    # same context, and provides the Rack::Test API methods (see Rack::Test::Session
    # for their documentation).
    #
    # Example:
    #
    #   class HomepageTest < Test::Unit::TestCase
    #     include Rack::Test::Methods
    #
    #     def app
    #       MyApp.new
    #     end
    #   end
    module Methods
      extend Forwardable

      def rack_mock_session(name = :default) # :nodoc:
        return build_rack_mock_session unless name

        @_rack_mock_sessions ||= {}
        @_rack_mock_sessions[name] ||= build_rack_mock_session
      end

      def build_rack_mock_session # :nodoc:
        Rack::MockSession.new(app)
      end

      def rack_test_session(name = :default) # :nodoc:
        return build_rack_test_session(name) unless name

        @_rack_test_sessions ||= {}
        @_rack_test_sessions[name] ||= build_rack_test_session(name)
      end

      def build_rack_test_session(name) # :nodoc:
        Rack::Test::Session.new(rack_mock_session(name))
      end

      def current_session # :nodoc:
        rack_test_session(_current_session_names.last)
      end

      def with_session(name) # :nodoc:
        _current_session_names.push(name)
        yield rack_test_session(name)
        _current_session_names.pop
      end

      def _current_session_names # :nodoc:
        @_current_session_names ||= [:default]
      end

      def digest_authorize(username, password)
        warn 'digest authentication support will be removed in rack-test 1.3', uplevel: 1
        current_session._digest_authorize(username, password)
      end

      METHODS = %i[
        request
        get
        post
        put
        patch
        delete
        options
        head
        custom_request
        follow_redirect!
        header
        env
        set_cookie
        clear_cookies
        authorize
        basic_authorize
        last_response
        last_request
      ].freeze

      def_delegators :current_session, *METHODS
    end
  end
end
