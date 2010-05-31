require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @database = Database.connect('TestDB')
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
    
    describe "inserting" do
      before(:each) do
        @document = {'_id' => 17, foo: 'bar', 'num' => 5.2, 'bool' => false}
      end
      
      
      
      it "should happen on the next tick" do
        EventMachine.expects(:next_tick).yields
        @this.insert @document
      end
      
      it "sends an InsertMessage to the database" do
        @database.expects(:<<).with(instance_of(InsertMessage))
        tick {@this.insert @document}
      end

      
    end
  end  
end