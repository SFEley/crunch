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
    
    describe "inserting" do
      before(:each) do
        @record = {foo: 'bar', 'num' => 5.2, 'bool' => false}
      end
      
      it "should happen on the next tick" do
        EventMachine.expects(:next_tick).yields
        tick do
          @this.insert @record
        end
      end
      
      it "sends an InsertMessage to the database" do
        @database.expects(:<<).with(instance_of(InsertMessage))
        tick do
          @this.insert @record
        end
      end

      
    end
  end  
end