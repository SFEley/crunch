require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @db = Database.connect 'crunch_test'
      @this = @db.collection :TestCollection
    end
    
    it "cannot be created directly" do
      ->{Collection.new}.should raise_error(CollectionError)
    end
    
    it "knows its database" do
      @this.database.should == @db
    end
    
    it "knows its name" do
      @this.name.should == 'TestCollection'
    end
    
    it "has an implicit query" do
      pending
    end
    
    it "passes unknown method calls to the implicit query" do
      pending
    end
    
    describe "inserting" do
      it "can insert a single document" do
        @this.insert 'foo' => 'bar'
        sleep 0.2
        verifier.find_one('foo' => 'bar').count.should == 1
      end
      
      it "returns the _id"
      
      it "can insert multiple documents"
      
      it "returns an _id array on multiple inserts"
    end
    
    describe "deleting" do
      pending
    end
    
    describe "updating" do
      pending
    end
  
  end
end