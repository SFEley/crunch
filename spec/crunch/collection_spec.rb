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
    
    it "knows its collection name" do
      @this.collection_name.should == 'crunch_test.TestCollection'
    end
    
    it "has an implicit query" do
      pending
    end
    
    it "passes unknown method calls to the implicit query" do
      pending
    end
    
    describe "inserting" do
      it "can insert a single document" do
        @this.insert 'foo' => 'bar', eleven: 11
        sleep 0.2
        verifier.find_one('foo' => 'bar')['eleven'].should == 11
      end
      
      it "can take a fieldset for a document" do
        @this.insert Fieldset.new('three' => 3, :five => 5.0)
        sleep 0.2
        verifier.find_one('three' => 3)['five'].should == 5.0
      end
        
      it "returns the _id" do
        id = @this.insert(too: 'tar')
        sleep 0.2
        verifier.find_one('too' => 'tar')['_id'].to_s.should == id.to_s
      end
      
      it "creates an ObjectID if no _id" do
        id = @this.insert(moo: :mar)
        id.should be_a(BSON::ObjectID)
        id.timestamp.should be_within(1).of(Time.now)
      end
        
      
      it "leaves the _id intact if one was provided" do
        id = Time.now.to_i
        @this.insert(woo: :war, '_id' => id).should == id
        sleep 0.2
        verifier.find_one('woo' => 'war')['_id'].should == id
      end
      
      it "can insert multiple documents" do
        id = Time.now.to_f
        @this.insert({qoo: 'qar'}, {qoo: :qas, _id: id}, {qoo: 7})
        sleep 0.2
        verifier.find('qoo' => {'$exists' => 1}).count.should == 3
      end
      
      it "returns an _id array on multiple inserts" do
        @this.insert({qoo: 'qar', '_id' => 1}, 
          {qoo: :qas, _id: 2}, {qoo: 7, _id: 3}).should == [1, 2, 3]
        sleep 0.2
        verifier.find('_id' => {'$in' => [1, 2, 3]}).count.should == 3
      end
        
    end
    
    describe "deleting" do
      pending
    end
    
    describe "updating" do
      pending
    end
  
  end
end