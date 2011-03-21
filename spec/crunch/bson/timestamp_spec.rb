#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  module BSON
    describe Timestamp do
      before(:each) do
        @existing = "\xE5\xB5\x87M\x11\x00\x00\x00"
        @date = Time.gm(2011, 3, 21, 20, 32, 37)
      end
      
      it "is null if given no parameters" do
        t = Timestamp.new
        t.bin.should == "\x00\x00\x00\x00\x00\x00\x00\x00"
        t.time.should == Time.at(0)
        t.counter.should == 0
      end
      
      it "returns itself if given a string parameter" do
        t = Timestamp.new(@existing)
        t.to_s.should == @existing
        t.time.utc.should == @date
        t.counter.should == 17
      end
  
    end
  end
end