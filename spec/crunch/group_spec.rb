require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Group do
    before(:each) do
      @database = Database.connect('crunch_test')
      @collection = @database.collection('TestCollection')
      @this = Group.send(:new, @collection)
    end
    
    it "requires a database" do
      ->{Group.new}.should raise_error(ArgumentError)
    end
    
    it "knows its database" do
      @this.database.should == @database
    end
    
    it "knows its full collection name" do
      @this.full_collection_name.should == 'crunch_test.TestCollection'
    end
        
    it "can take a list of fields at initialization" do
      this = Group.send(:new, @collection, data: [:foo, :bool, 'slappy'])
      this.data.should == [:foo, :bool, :slappy]
    end
    
    it "can set query parameters at initialization" do
      this = Group.send(:new, @collection, query: {'num' => {'$gt' => 3}})
      this.query.should == {'num' => {'$gt' => 3}}
    end
    
    it "can read query specs later" do
      pending
    end
  
  end
end