require_relative '../../spec_helper'

describe 'Rack::Test::Methods' do
  it '#rack_mock_session always creates new session if passed nil/false' do
    rack_mock_session(nil).wont_be_same_as rack_mock_session(nil)
    rack_mock_session(false).wont_be_same_as rack_mock_session(false)
  end

  it '#rack_mock_session reuses existing session if passed truthy value' do
    rack_mock_session(true).must_be_same_as rack_mock_session(true)
    rack_mock_session(:true).must_be_same_as rack_mock_session(:true)
  end

  it '#rack_test_session always creates new session if passed nil/false' do
    rack_test_session(nil).wont_be_same_as rack_test_session(nil)
    rack_test_session(false).wont_be_same_as rack_test_session(false)
  end

  it '#rack_test_session reuses existing session if passed truthy value' do
    rack_test_session(true).must_be_same_as rack_test_session(true)
    rack_test_session(:true).must_be_same_as rack_test_session(:true)
  end

  it '#build_rack_mock_session will be used if present' do
    session = Rack::Test::Session.new(app)
    define_singleton_method(:build_rack_mock_session){session}
    current_session.must_be_same_as session
  end
end
