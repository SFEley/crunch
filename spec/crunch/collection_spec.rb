require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Collection do
    before(:each) do
      @database = Database.connect 'crunch_test'
      @this = @database.collection 'TestCollection'
      @record = {'_id' => 17, foo: 'bar', 'num' => 5.2, 'bool' => false}
      @record2 = {'num' => 7.5, 'bool' => false}
    end
    
    it "must be instantiated from the database" do
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
    
    it "can create the collection if it doesn't exist" do
      pending
      other_collection = Collection.new @database, 'OtherCollection', create: true
      db = Mongo::Connection.new.db('crunch_test')
      db.collection_names.should include('OtherCollection')
    end
    
    describe "retrieval" do
      before(:each) do
        tick do
          @this.insert @record
          @this.insert @record2
        end
      end
      
      it "can return a document" do
        @this.document(17).should be_a(Document)
      end
      
      it "can return a group" do
        pending
        group = @this.group(bool: false)
        group.should be_a(Collection)
        group.should have(2).documents
      end
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
        sleep 1
        verifier.find_one('_id' => 17).should == {'_id' => 17, 'foo' => 'bar', 'num' => 5.2, 'bool' => false}
      end
      
      it "returns a Crunch::Document" do
        doc = @this.insert @record
        doc.should be_a(Crunch::Document)
      end
      
    end
    
    describe "updating multiple records" do
      before(:each) do
        tick do
          @this.insert @record
          @this.insert @record2
        end
      end
      
      describe "message setup" do
        before(:each) do
         @database.stubs(:<<).returns(true)  # If we don't do this, our message type checking will throw exceptions
        end

        it "sets the selection if one exists" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(selector: {'bool' => false}))
          @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})
        end

        it "pushes the ID in if one is given" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(selector: {'bool' => false, '_id' => 17}))
          @this.update(selector: {'bool' => false}, id: 17, update: {'$set' => {'foo' => 'tar'}})
        end        

        it "takes the update as passed" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(update: {'$set' => {'foo' => 'tar'}}))
          @this.update(selector: {'bool' => false}, id: 17, update: {'$set' => {'foo' => 'tar'}})
        end

        it "passes the upsert value in" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(upsert: false))
          @this.update(selector: {'bool' => false}, id: 17, update: {'$set' => {'foo' => 'tar'}}, upsert: false)
        end

        it "passes the multi value in if given" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(multi: false))
          @this.update(selector: {'bool' => false}, id: 17, update: {'$set' => {'foo' => 'tar'}}, multi: false)
        end

        it "defaults the multi value to true if not given" do
          UpdateMessage.expects(:new).with(instance_of(Collection), has_entry(multi: true))
          tick do
            @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})        
          end
        end
        
      end
      
      it "happens on the next tick" do
        EventMachine.expects(:next_tick).yields
        @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})
      end
      
      it "sends an UpdateMessage to the database" do
        @database.expects(:<<).with(instance_of(UpdateMessage))
        @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})
      end
      
      it "updates records in Mongo" do
        @this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}})
        sleep 0.5
        verifier.find('foo' => 'tar').count.should == 2
      end

      it "updates just one record if multi is false" do
        tick{@this.update(selector: {'bool' => false}, update: {'$set' => {'foo' => 'tar'}}, multi: false)}
        sleep 0.5
        verifier.find('foo' => 'tar').count.should == 1
      end
      
      it "can upsert a record" do
        @this.update(selector: {'cool' => 'car'}, update: {'$inc' => {'doors' => 2}}, upsert: true)
        sleep 0.5
        verifier.find_one('cool' => 'car')['doors'].should == 2
      end
      
      
    end
  end  
end