require File.dirname(__FILE__) + "/spec_helper"

describe Rack::Test do
  before do
    @session = Rack::Test::Session.new(App)
  end

  def response
    @session.last_response
  end

  describe "#get" do
    it "requests URL" do
      @session.get("/")
      response.should be_ok
    end
  end
end
