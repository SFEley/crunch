require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  # Test the Connection module without having to screw around with EventMachine
  class DummyConnection
    include Connection
  end
  
  describe Connection do
    before(:each) do
      @sender = stub "Document"
      @message = stub "QueryMessage", sender: @sender, request_id: 1337
      @this = DummyConnection.new
    end
    
    it "can receive data" do
      @this.should respond_to(:receive_data)
    end
    

  end
end