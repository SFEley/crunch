require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Group do
    before(:each) do
      @database = Database.connect('crunch_test')
      @this = Group.new(@database, 'TestCollection')
    end
    
    it "requires a database" do
      ->{Group.new}.should raise_error(ArgumentError)
    end
    
    it "requires a collection name" do
      ->{Group.new(@database)}.should raise_error(ArgumentError)
    end
    
    it "knows its database" do
      @this.database.should == @database
    end
    
    it "knows its collection name" do
      @this.collection_name.should == 'TestCollection'
    end
    
    it "knows its full collection name" do
      @this.full_collection_name.should == 'crunch_test.TestCollection'
    end
        
    it "can take a list of fields at initialization" do
      pending
    end
    
    it "can set query parameters at initialization" do
      pending
    end
    
    it "can read query specs later" do
      pending
    end
  
  end
end