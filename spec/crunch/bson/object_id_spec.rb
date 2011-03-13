#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  module BSON
    describe "ObjectID" do
      before(:each) do
        @this = ObjectID.new
      end
      
      describe "creation" do
        it "is 12 bytes long" do
          @this.bin.bytesize.should == 12
        end

        it "knows its machine ID" do
          @this.machine_id.should > 0
        end
        
        it "knows its process ID" do
          @this.process_id.should > 0
        end
        
        it "knows its timestamp" do
          @this.timestamp.should be_within(1).of(Time.now)
        end
        
        it "has an incrementing counter" do
          that = ObjectID.new
          @this.counter.should == that.counter - 1
        end
        
        it "returns hex by default" do
          @this.to_s.size.should == 24
          @this.to_s.should =~ /[0-9a-f]/i
        end
        
        it "has all the pieces" do
          @this.to_s[0..7].hex.should == @this.timestamp.to_i
          @this.to_s
        end
        
      end
      
    end
  end
end