#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  module BSON
    describe "- from_hash method" do
      it "converts simple hashes" do
        this = {'hi' => 'ho', 'three' => 3}
        BSON.from_hash(this).should == "\e\x00\x00\x00\x02hi\x00\x03\x00\x00\x00ho\x00\x10three\x00\x03\x00\x00\x00\x00"
      end
      
      it "converts empty hashes" do
        BSON.from_hash({}).should == "\x05\x00\x00\x00\x00"
      end
      
    end
    
  end
end
