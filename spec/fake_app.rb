require "sinatra/base"

module Rack
  module Test

    class FakeApp < Sinatra::Default
      head "/" do
        "meh"
      end

      get "/" do
        "Hello, GET: #{params.inspect}"
      end
      
      get "/redirect" do
        redirect "/redirected"
      end

      get "/redirected" do
        "You've been redirected"
      end

      get "/set-cookie" do
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
