module Crunch
  shared_examples_for "a Request" do
    it "can start the 'begin' timer" do
      @this.begin
      @this.began.should be_within(1).of(Time.now)
    end
    
    it "has a request ID that's global across classes" do
      that = DummyRequest.new
      @this.request_id.should be_within(1.1).of(that.request_id)
    end
    
    it "has an opcode" do
      BSON.to_int(@this.class.opcode).should >= 0
    end
    
    it "has a fixed size header" do
      @this.header.bytesize.should == 16
    end
    
    it "has a binary message" do
      @this.to_s.encoding.should == Encoding::BINARY
    end
    
    it "delivers itself with the header and the body" do
      @this.to_s.should == @this.header + @this.body
    end
    
    it "has the right length" do
      BSON.to_int(@this.to_s[0..3]).should == @this.body.bytesize + 16
    end
    
    it "knows its sender" do
      @this.sender.should_not be_nil
      @this.sender.should == @sender
    end
    
  end
end