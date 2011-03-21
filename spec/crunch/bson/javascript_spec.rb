#encoding: BINARY

require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  module BSON 
    describe "- javascript method" do
      before(:each) do
        @code = "function() { return this; }"
        @scope = {'this' => 5}
      end
      it "takes a string" do
        BSON.javascript(@code).to_s.should == "\x1C\x00\x00\x00function() { return this; }\x00"
      end
      
      it "can take a scope" do
        BSON.javascript(@code, @scope).to_s.should == "3\x00\x00\x00\x1C\x00\x00\x00function() { return this; }\x00\x0F\x00\x00\x00\x10this\x00\x05\x00\x00\x00\x00"
      end
    end
    
    describe Javascript do
      before(:each) do
        @code = "function() { return this; }"
        @scope = {'this' => 5}
      end

      it "takes a code string" do
        Javascript.new(@code).to_s.should == "\x1C\x00\x00\x00function() { return this; }\x00"
      end
      
      it "can take a scope" do
        Javascript.new(@code, @scope).to_s.should == "3\x00\x00\x00\x1C\x00\x00\x00function() { return this; }\x00\x0F\x00\x00\x00\x10this\x00\x05\x00\x00\x00\x00"
      end
      
      it "can return its element without scope" do
        Javascript.new(@code).element.should == [13, 32, "\x1C\x00\x00\x00function() { return this; }\x00"]
      end
      
      it "can return its element with scope" do
        Javascript.new(@code, @scope).element.should == [15, 51, "3\x00\x00\x00\x1C\x00\x00\x00function() { return this; }\x00\x0F\x00\x00\x00\x10this\x00\x05\x00\x00\x00\x00"]
      end
    end
  end
end