require File.dirname(__FILE__) + '/../spec_helper'
require_relative '../shared_examples/querist_shared_spec'

module Crunch
  describe Document do
    BSON_STRING = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    BSON_WITH_ID = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    
    before(:each) do
      @verifier_collection.insert '_id' => 7, foo: 'bar', too: :tar, slappy: 17
      @database = Database.connect 'crunch_test'
      @collection = @database.collection 'TestCollection'
      @this = Document.send :new, @collection, id: 7, data: {foo: 'bar', too: :tar, slappy: 17}
    end
    
    it_should_behave_like "a Querist"
    
    it "must be instantiated from a collection" do
      ->{Document.new}.should raise_error(NoMethodError)
    end
    
    it "can take an ID" do
      @this['_id'].should == 7
    end
    
    it "has a simple ID method" do
      @this.id.should == @this['_id']
    end
    
    it "can take other data" do
      @this['too'].should == :tar
    end
     
    it "knows how to serialize itself" do
      pending
      @this['_id'] = 7  # For predictability
      "#{@this}".should == BSON_WITH_ID
    end
    

  end
end