module Crunch
  shared_examples_for "an Agent" do
    before(:each) do
    end
  
    it "knows its collection name" do
      @this.collection_name.should == 'crunch_test.TestCollection'
    end

    it "can have query conditions" do
      @this.should respond_to(:query)
    end
  
    it "has fields queried on" do
      @this.should respond_to(:fields)
    end
  
    it "has a starting number" do
      @this.should respond_to(:skip)
    end
  
    it "has a limit" do
      @this.should respond_to(:limit)
    end
  
    describe "querying" do
    
      it "goes to the database" do
        @database.expects(:<<).with(instance_of(Crunch::QueryMessage))
        tick {@this.query}
      end

    end

    describe "receiving responses" do

      it "fails if the size is wrong" do
        result = nil
        @this.errback{|exception| result = exception}
        @this.set_deferred_status(:succeeded, @reply_data[0..260])
        result.should be_a(HeaderError)
        result.message.should =~ /261.*262/
      end
      
      it "fails if the response_to is wrong" do
        QueryMessage.any_instance.stubs(:request_id).returns(-1)
        result = nil
        @this.errback{|exception| result = exception}
        tick {@this.set_deferred_status(:succeeded, @reply_data)}
        result.should be_a(HeaderError)
        result.message.should =~ /-1.*9/
      end
        
      it "fails if the response flags show an error from MongoDB"
      
      it "returns the error message if the response flags show an error from MongoDB"
    end
  end
end