require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe ShutdownRequest do
    before(:each) do
      @this = ShutdownRequest.new
    end
    
    behaves_like "a Request"
    
    it "has a zero opcode to indicate that it shouldn't be sent to Mongo" do
      BSON.to_int(@this.class.opcode).should == 0
    end
    
    it "has a plain literal body" do
      @this.body.should == "SHUTDOWN"
    end
    
    
    
    
  end
end