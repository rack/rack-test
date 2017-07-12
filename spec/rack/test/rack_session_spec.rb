require "spec_helper"

describe Rack::Test::Session do
  after :each do
    # current_session.rack_session = nil
  end

  it "allows setting session via env" do
    current_session.rack_session[:user_id] = "1337"
    get "/session"
    last_response.body.to_s.should == '{:user_id=>"1337"}'
    current_session.rack_session = nil
  end

  pending "makes the session data readable via env" do
    # TODO: Not sure this is actually desired functionality, since you probably shouldn't be asserting on this stuff in tests
    get "/session/set", :key => :foo, :value => 42
    current_session.rack_session.should == { :foo => "42" }
  end

end
