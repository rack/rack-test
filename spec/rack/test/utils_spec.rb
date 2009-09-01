require "spec_helper"

describe Rack::Test::Utils do
  include Rack::Test::Utils

  describe "build_nested_query" do
    it "converts empty strings to =" do
      build_nested_query("").should == "="
    end

    it "converts nil to =" do
      build_nested_query(nil).should == "="
    end

    it "converts hashes" do
      build_nested_query(:a => 1).should == "a=1"
    end

    it "converts hashes with multiple keys" do
      hash = { :a => 1, :b => 2 }
      ["a=1&b=2", "b=2&a=1"].should include(build_nested_query(hash))
    end

    it "converts arrays with one element" do
      build_nested_query(:a => [1]).should == "a[]=1"
    end

    it "converts arrays with multiple elements" do
      build_nested_query(:a => [1, 2]).should == "a[]=1&a[]=2"
    end

    it "converts nested hashes" do
      build_nested_query(:a => { :b => 1 }).should == "a[b]=1"
    end

    it "converts arrays nested in a hash" do
      build_nested_query(:a => { :b => [1, 2] }).should == "a[b][]=1&a[b][]=2"
    end

    it "converts arrays of hashes" do
      build_nested_query(:a => [{ :b => 2}, { :c => 3}]).should == "a[][b]=2&a[][c]=3"
    end
  end
end
