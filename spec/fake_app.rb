require "sinatra/base"

module Rack
  module Test
    
    class FakeApp < Sinatra::Default
      get "/" do
        "Hello, GET: #{params.inspect}"
      end
      
      get "/set-cookie" do
        puts request.inspect
        cookie = request.cookies["value"] || 0
        response.set_cookie("value", cookie.to_i + 1)
        
        "Value: #{cookie}"
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