#encoding: BINARY
require 'spec_helper'
require 'date'

module Crunch
  module BSON
    describe ObjectID do
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
        
        it "returns hex when asked for a string" do
          @this.to_s.size.should == 24
          @this.to_s.should =~ /[0-9a-f]/i
        end
        
        it "has all the pieces" do
          @this.to_s[0..7].hex.should == @this.timestamp.to_i
          @this.to_s[8..13].hex.should == @this.machine_id
          @this.to_s[14..17].hex.should == @this.process_id
          @this.to_s[18..23].hex.should == @this.counter
        end
      end
      
      describe "importing" do
        before(:each) do
          @binary = "M~\x1D_\xA2y\x0E\x03\xC3\x00\x00\x01"
          @binary.force_encoding('BINARY')
          @hex = "4d7e1d5fa2790e03c3000001"
          @this = ObjectID.new(@binary)
        end
        it "accepts a binary string value" do
          ObjectID.new(@binary).hex.should == @hex
        end
        
        it "accepts a hex value" do
          ObjectID.new(@hex).bin.should == @binary
        end
        
        it "complains if given neither" do
          ->{ObjectID.new('foo')}.should raise_error(BSONError, /binary or hex string/)
        end
        
        it "knows its timestamp" do
          @this.timestamp.utc.should == DateTime.parse('2011-03-14 13:51:27 UTC').to_time
        end
        
        it "knows its machine ID" do
          @this.machine_id.should == 10647822
        end
        
        it "knows its process ID" do
          @this.process_id.should == 963
        end
        
        it "knows its counter" do
          @this.counter.should == 1
        end
          
      end
      
    end
  end
end