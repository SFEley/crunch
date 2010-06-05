require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @database = Database.connect('crunch_test')
      @this = Collection.send(:new, @database, 'TestCollection')
      @record = {'_id' => 17, foo: 'bar', 'num' => 5.2, 'bool' => false}
      @record2 = {'num' => 7.5, 'bool' => false}
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
      @this.full_name.should == "crunch_test.TestCollection"
    end
    
    describe "inserting" do
      
      it "should happen on the next tick" do
        EventMachine.expects(:next_tick).yields
        @this.insert @record
      end
      
      it "sends an InsertMessage to the database" do
        @database.expects(:<<).with(instance_of(InsertMessage))
        @this.insert @record
      end

      it "inserts the record into Mongo" do
        @this.insert @record
        sleep 0.5
        verifier.find_one('_id' => 17).should == {'_id' => 17, 'foo' => 'bar', 'num' => 5.2, 'bool' => false}
      end
      
      it "returns a Crunch::Document" do
        doc = @this.insert @record
        doc.should be_a(Crunch::Document)
      end
      
    end
    
    describe "updating multiple records" do
      before(:each) do
        @this.insert @record
        @this.insert @record2
      end
      
      it "happens on the next tick" do
        EventMachine.expects(:next_tick).yields
        @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})
      end
      
      it "sends an UpdateMessage to the database"
      it "updates the record in Mongo"
    end
  end  
end