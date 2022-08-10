# frozen-string-literal: true

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

  it '#build_rack_test_session will use defined app' do
    envs = []
    app = proc{|env| envs << env; [200, {}, []]}
    define_singleton_method(:app){app}

    get '/'
    envs.first['PATH_INFO'].must_equal '/'
    envs.first['HTTP_HOST'].must_equal 'example.org'
  end

  it '#build_rack_test_session will use defined default_host' do
    envs = []
    app = proc{|env| envs << env; [200, {}, []]}
    define_singleton_method(:app){app}
    define_singleton_method(:default_host){'foo.example.com'}

    get '/'
    envs.first['PATH_INFO'].must_equal '/'
    envs.first['HTTP_HOST'].must_equal 'foo.example.com'
  end
end
