require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @database = stub("Database", name: 'TestDB')
      @this = Collection.send(:new, @database, 'TestCollection')
    end
    
    it "cannot be created directly" do
      ->{Collection.new}.should raise_error(NoMethodError)
    end
    
    it "knows its database" do
      @this.database.should == @database
    end
    
    it "knows its name" do
      @this.name.should == "TestCollection"
    end
    
    it "knows its full name" do
      @this.full_name.should == "TestDB.TestCollection"
    end
  end  
end