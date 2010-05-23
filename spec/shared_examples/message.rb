shared_examples_for "a Message" do
  it "has a request ID that increments across classes" do
      (@this.class.request_id - Message.request_id).should == -1      
  end
  
  it "knows how to deliver itself" do
    @this.deliver.encoding.should == Encoding::BINARY
  end
  
  it "starts with its size" do
    @this.deliver[0..3].unpack('V').first.should == @this.deliver.size
  end
  
  it "contains a request ID" do
    @this.deliver[4..7].unpack('V').first.should be_close(Message.request_id, 2)
  end
  
  it "contains a response ID if called for" do
    @this.deliver[8..11].unpack('V').first.should == @this.response_id
  end
  
  it "contains the opcode" do
    @this.deliver[12..15].unpack('V').first.should == @this.class.opcode
  end
  
  it "contains the body" do
    @this.deliver[16..-1].should == @this.body
  end

end
