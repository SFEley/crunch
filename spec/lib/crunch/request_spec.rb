require 'spec_helper'

module Crunch
  describe Request do
    before(:each) do
      @sender = DummySender.new
      @message = "To sit in sullen silence..."
      @this = Request.new(@sender, message: @message)
    end
    
    behaves_like "a Request"
    
    it "has an opcode for OP_MSG" do
      BSON.to_int(@this.class.opcode).should == 1000
    end
    
    it "has its message as the body" do
      @this.body.should == "To sit in sullen silence...\x00"
    end
    
    it "null terminates the message" do
      @this.body.bytesize.should == @message.bytesize + 1
    end
    
  end
end