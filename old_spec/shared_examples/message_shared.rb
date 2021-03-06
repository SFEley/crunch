module Crunch
  shared_examples_for "a Message" do
  
    it "has a request ID that increments across classes" do
        (@this.class.request_id - Message.request_id).should == -1      
    end
  
    it "knows how to deliver itself" do
      @this.deliver.encoding.should == Encoding::BINARY
    end
    
    it "knows when it was delivered" do
      @this.delivered_at.should be_nil
      @this.deliver
      @this.delivered_at.should be_within(1).of(Time.now)
    end
    
    it "starts with its size" do
      @this.deliver[0..3].unpack('V').first.should == @this.deliver.size
    end
  
    it "contains a request ID" do
      @this.deliver[4..7].unpack('V').first.should be_close(Message.request_id, 2)
    end
  
    it "contains a response ID of 0" do
      @this.deliver[8..11].unpack('V').first.should == 0
    end
  
    it "contains the opcode" do
      @this.deliver[12..15].unpack('V').first.should == @this.class.opcode
    end
  
    it "contains the body" do
      @this.deliver[16..-1].should == @this.body
    end

  end
end