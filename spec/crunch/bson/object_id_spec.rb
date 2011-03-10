require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  module BSON
    describe "ObjectID" do
      before(:each) do
        @this = ObjectID.new
      end
      
      it "is 12 bytes long" do
        @this.to_s.bytesize.should == 12
      end
      
      it "knows a machine ID" do
        @this.class.machine_id.bytesize.should == 3
      end
      
      it "knows a process ID" do
        @this.class.process_id.bytesize.should == 2
      end
      
      it "knows its timestamp" do
        Time.at(@this.timestamp.unpack('N').first).should be_within(1).of(Time.now)
      end
      
    end
  end
end