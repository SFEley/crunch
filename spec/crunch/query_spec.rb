require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Query do
    before(:each) do
      @database = Database.connect('crunch_test')
      @collection = @database.collection('TestCollection')
      @this = Query.send(:new, @collection)
    end
    
    it "requires a database" do
      ->{Query.new}.should raise_error(ArgumentError)
    end
    
    it "knows its database" do
      @this.database.should == @database
    end
    
    it "knows its full collection name" do
      @this.full_collection_name.should == 'crunch_test.TestCollection'
    end
        
    it "can take a list of fields at initialization" do
      this = Query.send(:new, @collection, fields: [:foo, :bool, 'slappy'])
      this.options[:fields].should == [:foo, :bool, 'slappy']
    end
    
    it "can set query conditions at initialization" do
      this = Query.send(:new, @collection, conditions: {'num' => {'$gt' => 3}})
      this.conditions.should == {'num' => {'$gt' => 3}}
    end
    
  end
end