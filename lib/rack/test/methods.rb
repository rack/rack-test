module Rack
  module Test
    
    module Methods
      
      def self.delegate_to_rack_test_session(*meths)
        meths.each do |meth|
          self.class_eval <<-RUBY
            def #{meth}(*args, &blk)
              rack_test_session.#{meth}(*args, &blk)
            end
          RUBY
        end
      end
      
      def rack_test_session
        @_rack_test_session ||= Rack::Test::Session.new(app)
      end
      
      delegate_to_rack_test_session \
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
        
        
    end
    
  end
end