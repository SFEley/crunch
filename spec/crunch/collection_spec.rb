require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @db = Database.connect 'crunch_test'
      @this = @db.collection :test_collection
    end
    
    it "cannot be created directly" do
      ->{Collection.new}.should raise_error(CollectionError)
    end
    
    it "knows its database" do
      @this.database.should == @db
    end
    
    it "knows its name" do
      @this.name.should == 'test_collection'
    end
  
  end
end