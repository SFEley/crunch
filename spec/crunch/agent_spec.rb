require File.dirname(__FILE__) + '/../spec_helper'
require_relative '../shared_examples/agent_shared_spec'

module Crunch
  describe Agent do

    before(:each) do
      @database = Database.connect 'crunch_test'
      @collection = @database.collection 'TestCollection'
      @query = Fieldset.new '_id' => 7
      @this = Agent.new @collection, @query
      @reply_data = [0x06,0x01,0x00,0x00,0x23,0x38,0x27,0xDE,0x09,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0xE2,0x00,0x00,0x00,0x07,0x5F,0x69,0x64,0x00,0x4C,0x44,0xD1,0x8D,0x3F,0x16,0x51,0x03,0x02,0x00,0x00,0x01,0x0E,0x66,0x6F,0x6F,0x00,0x04,0x00,0x00,0x00,0x62,0x61,0x72,0x00,0x01,0x6E,0x75,0x6D,0x6D,0x79,0x00,0x3B,0xFC,0x35,0x59,0xA3,0x0E,0x27,0x40,0x02,0x73,0x74,0x72,0x69,0x6E,0x67,0x79,0x00,0xA3,0x00,0x00,0x00,0x4E,0x6F,0x77,0x20,0x69,0x73,0x20,0x74,0x68,0x65,0x20,0x74,0x69,0x6D,0x65,0x20,0x66,0x6F,0x72,0x20,0x61,0x6C,0x6C,0x20,0x67,0x6F,0x6F,0x64,0x20,0x6D,0x65,0x6E,0x20,0x74,0x6F,0x20,0x63,0x6F,0x6D,0x65,0x20,0x74,0x6F,0x20,0x74,0x68,0x65,0x20,0x61,0x69,0x64,0x20,0x6F,0x66,0x20,0x74,0x68,0x65,0x69,0x72,0x20,0x70,0x61,0x72,0x74,0x79,0x2E,0x20,0x54,0x6F,0x20,0x73,0x69,0x74,0x20,0x69,0x6E,0x20,0x73,0x75,0x6C,0x6C,0x65,0x6E,0x20,0x73,0x69,0x6C,0x65,0x6E,0x63,0x65,0x20,0x6F,0x6E,0x20,0x61,0x20,0x64,0x75,0x6C,0x6C,0x20,0x64,0x61,0x72,0x6B,0x20,0x64,0x6F,0x63,0x6B,0x2E,0x2E,0x2E,0x20,0x20,0x54,0x68,0x65,0x20,0x71,0x75,0x69,0x63,0x6B,0x20,0x62,0x72,0x6F,0x77,0x6E,0x20,0x66,0x6F,0x78,0x20,0x6A,0x75,0x6D,0x70,0x65,0x64,0x20,0x6F,0x76,0x65,0x72,0x20,0x74,0x68,0x65,0x20,0x6C,0x61,0x7A,0x79,0x20,0x64,0x6F,0x67,0x2E,0x00,0x00,0x06,0x01,0x00,0x00,0x23,0x38,0x27,0xDE,0x09,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0xE2,0x00,0x00,0x00,0x07,0x5F,0x69,0x64,0x00,0x4C,0x44,0xD1,0x8D,0x3F,0x16,0x51,0x03,0x02,0x00,0x00,0x01,0x0E,0x66,0x6F,0x6F,0x00,0x04,0x00,0x00,0x00,0x62,0x61,0x72,0x00,0x01,0x6E,0x75,0x6D,0x6D,0x79,0x00,0x3B,0xFC,0x35,0x59,0xA3,0x0E,0x27,0x40,0x02,0x73,0x74,0x72,0x69,0x6E,0x67,0x79,0x00,0xA3,0x00,0x00,0x00,0x4E,0x6F,0x77,0x20,0x69,0x73,0x20,0x74,0x68,0x65,0x20,0x74,0x69,0x6D,0x65,0x20,0x66,0x6F,0x72,0x20,0x61,0x6C,0x6C,0x20,0x67,0x6F,0x6F,0x64,0x20,0x6D,0x65,0x6E,0x20,0x74,0x6F,0x20,0x63,0x6F,0x6D,0x65,0x20,0x74,0x6F,0x20,0x74,0x68,0x65,0x20,0x61,0x69,0x64,0x20,0x6F,0x66,0x20,0x74,0x68,0x65,0x69,0x72,0x20,0x70,0x61,0x72,0x74,0x79,0x2E,0x20,0x54,0x6F,0x20,0x73,0x69,0x74,0x20,0x69,0x6E,0x20,0x73,0x75,0x6C,0x6C,0x65,0x6E,0x20,0x73,0x69,0x6C,0x65,0x6E,0x63,0x65,0x20,0x6F,0x6E,0x20,0x61,0x20,0x64,0x75,0x6C,0x6C,0x20,0x64,0x61,0x72,0x6B,0x20,0x64,0x6F,0x63,0x6B,0x2E,0x2E,0x2E,0x20,0x20,0x54,0x68,0x65,0x20,0x71,0x75,0x69,0x63,0x6B,0x20,0x62,0x72,0x6F,0x77,0x6E,0x20,0x66,0x6F,0x78,0x20,0x6A,0x75,0x6D,0x70,0x65,0x64,0x20,0x6F,0x76,0x65,0x72,0x20,0x74,0x68,0x65,0x20,0x6C,0x61,0x7A,0x79,0x20,0x64,0x6F,0x67,0x2E,0x00,0x00,0x06,0x01,0x00,0x00,0x23,0x38,0x27,0xDE,0x09,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0xE2,0x00,0x00,0x00,0x07,0x5F,0x69,0x64,0x00,0x4C][0..261].pack('c*')
      QueryMessage.any_instance.stubs(:request_id).returns(9)
      
    end

    behaves_like "an Agent"
    
      
    it "gets data back from the server" do
      result = nil
      @this.callback{|header, documents| result = documents}
      @this.set_deferred_status(:succeeded, @reply_data)
      result.should == @reply_data[36..261]
    end

    describe ".run method" do
      before(:each) do
        @database.stubs(:<<).with {|message| message.sender.set_deferred_status(:succeeded, @reply_data); true}
      end
      
      it "takes the same parameters as .new" do
        ->{Agent.run @collection, @query, limit: 1}.should_not raise_error
      end
      
      it "runs the query" do
        @database.expects(:<<)
        tick{Agent.run @collection, @query}
      end
      
      it "sets the block as a callback" do
        result = nil
        tick{Agent.run(@collection, @query, {}) {|header, documents| result = documents}}
        result.should == @reply_data[36..261]
      end
      
      it "returns an Agent object" do
        Agent.run(@collection, @query).should be_a(Agent)
      end
    end
  end
end