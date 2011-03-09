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
      unbson(@this.opcode).should >= 0
    end
    
    it "has a fixed size header" do
      @this.header.byte_size.should == 16
    end
    
    it "has a binary body" do
      @this.body.should.encoding.should == Encoding::BINARY
    end
    
    it "delivers itself with the header and the body" do
      @this.to_s.should == @this.header + @this.body
    end
    
  end
end