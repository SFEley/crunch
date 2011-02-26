require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Query do
    before(:each) do
      @database = Database.connect('crunch_test')
      @collection = @database.collection('TestCollection')
      @this = @collection.query
    end
    
    it "cannot be instantiated by itself" do
      ->{Query.new}.should raise_error(ArgumentError)
    end
    
    it "knows its database" do
      @this.database.should == @database
    end
    
    it "knows its full collection name" do
      @this.full_collection_name.should == 'crunch_test.TestCollection'
    end
        
    it "can take a list of fields at initialization" do
      this = @collection.query fields: [:foo, :bool, 'slappy']
      this.options[:fields].should == {'foo' => 1, 'bool' => 1, 'slappy' => 1}
    end
    
    it "has a null fields list if not supplied" do
      @this.options[:fields].should be_nil
    end
    
    it "can set query conditions at initialization" do
      this = @collection.query conditions: {'num' => {'$gt' => 3}}
      this.conditions.should == {'num' => {'$gt' => 3}}
    end
    
    it "can set the query sort order at initialization" do
      this = @collection.query sort: {'num' => 1}
      this.options[:sort].should == {'num' => 1}
    end
    
    it "has a null sort order if not supplied" do
      @this.options[:sort].should be_nil
    end
    
  end
end