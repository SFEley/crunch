module Crunch
  shared_examples_for "a Request" do
    it "can start the 'begin' timer" do
      @this.begin
      @this.began.should be_within(1).of(Time.now)
    end
    
    it "delivers itself as a binary string" do
      @this.to_s.encoding.should == Encoding::BINARY
    end
    
    it "has a request ID that's global across classes" do
      that = DummyRequest.new
      @this.request_id.should be_within(1.1).of(that.request_id)
    end
  end
end