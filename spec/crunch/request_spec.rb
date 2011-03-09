require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Request do
    before(:each) do
      @this = Request.new(message: "To sit in sullen silence...")
    end
    
    behaves_like "a Request"
    
    it "has an opcode for OP_MSG" do
      @this.class.opcode.should == 1000
    end
    
    it "has its message as the body" do
      @this.body.should == "To sit in sullen silence..."
    end
    
    
  end
end