require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @database = Database.connect('crunch_test')
      @this = Collection.send(:new, @database, 'TestCollection')
      @document = {'_id' => 17, foo: 'bar', 'num' => 5.2, 'bool' => false}
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
        @this.insert @document
      end
      
      it "sends an InsertMessage to the database" do
        @database.expects(:<<).with(instance_of(InsertMessage))
        tick {@this.insert @document}
      end

      it "inserts the record into Mongo" do
        @this.insert @document
        sleep 0.5
        verifier.find_one('_id' => 17).should == {'_id' => 17, 'foo' => 'bar', 'num' => 5.2, 'bool' => false}
      end
      
      it "returns a Crunch::Document" do
        doc = @this.insert @document
        doc.should be_a(Crunch::Document)
      end
      
    end
    
    describe "updating" do
      before(:each) do
        tick {@this.insert @document}
      end
      
      it "happens on the next tick" do
        EventMachine.expects(:next_tick).yields
        @this.update(id: 17, update: {'$set' => {'foo' => 'tar'}})
      end
      
      it "sends an UpdateMessage to the database"
      it "updates the record in Mongo"
    end
  end  
end