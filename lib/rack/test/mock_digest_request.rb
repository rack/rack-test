# :nocov:
require 'rack/auth/digest' unless defined?(Rack::Auth::Digest)
# :nocov:

module Rack
  module Test
    class MockDigestRequest_ # :nodoc:
      def initialize(params)
        @params = params
      end

      def method_missing(sym)
        if @params.key? k = sym.to_s
          return @params[k]
        end

        super
      end

      def method
        @params['method']
      end

      def response(password)
        Rack::Auth::Digest::MD5.new(nil).send :digest, self, password
      end
    end
    MockDigestRequest = MockDigestRequest_
    deprecate_constant :MockDigestRequest if respond_to?(:deprecate_constant, true)
  end
end
