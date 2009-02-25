require "sinatra/base"

module Rack
  module Test
    
    class FakeApp < Sinatra::Default
      get "/" do
        "Hello, GET: #{params.inspect}"
      end
      
      post "/" do
        "Hello, POST: #{params.inspect}"
      end
      
      put "/" do
        "Hello, PUT: #{params.inspect}"
      end
      
      delete "/" do
        "Hello, DELETE: #{params.inspect}"
      end
    end
    
  end
end