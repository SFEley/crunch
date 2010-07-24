require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Querist do
    before(:each) do
      @database = stub "Database"
      @collection = stub "Collection", database: @database, full_name: 'crunch_test.TestCollection'
      @owner = stub "Document or Group", collection: @collection
      @query = Fieldset.new '_id' => 7
      @this = Querist.new @owner, @query
      
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
      before(:each) do
        @result = Fieldset.new '_id' => 5.5, 'foo' => :bar
      end
    
      it "goes to the database" do
        @database.expects(:<<).with(instance_of(Crunch::QueryMessage))
        @this.refresh
      end
     
      it "gets data back from the server" do
        Thread.abort_on_exception = true
        @this.expects(:receive_data)# .with(@result)
        tick do
          @this.set_deferred_status(:succeeded, @result)
        end
      end
    end
  end
end