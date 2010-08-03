require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Document do
    BSON_STRING = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    BSON_WITH_ID = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"

    def wait_for_ready
      increment = 0.0005
      sleep(increment *= 2) until @this.ready? || increment > 5
      raise "Document retrieval timed out!" unless @this.ready?
      tick
    end
    
    before(:each) do
      @database = Database.connect 'crunch_test'
      @collection = @database.collection 'TestCollection'
      @this = Document.send :new, @collection, data: {'_id' => 7, foo: 'bar', too: :tar, slappy: 17}
    end
    
    it "must be instantiated from a collection" do
      ->{Document.new}.should raise_error(NoMethodError)
    end
    
    it "knows its collection" do
      @this.collection.should == @collection
    end
    
    it "knows the query that was passed to it" do
      this = Document.send :new, @collection, query: {foo: 'bar'}
      this.query.should be_a(Fieldset)
      this.query['foo'].should == 'bar'
    end
    
    it "sets up a query with the ID if one was passed to it" do
      this = Document.send :new, @collection, query: {foo: 'bar'}, id: 11.2
      this.query.should be_a(Fieldset)
      this.query['foo'].should == 'bar'
      this.query['_id'].should == 11.2
    end
    
    it "defaults its query to the ID if none was given" do
      @this.query['_id'].should == 7
    end
    
    it "knows its other options" do
      @this.options[:limit].should == 1
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
      @this.to_bson.should == BSON_WITH_ID
    end
    
    it "knows when it's ready" do
      @this.should be_ready
    end      

    describe "querying" do
      before(:each) do
        @verifier_collection.insert '_id' => 7, foo: 'bar', too: :tar, slappy: 17
        @this = Document.send(:new, @collection, id: 7)
      end
      
      
      it "knows it isn't ready" do
        @this.should_not be_ready
      end
      
      it "can begin a retrieval" do
        @this.send(:retrieve).should be_a(DocumentQuerist)
      end
      
      it "returns the same querist on each retrieval if one's in process" do
        # Do our best to make sure the query doesn't return before we do our comparisons
        q = @this.send(:retrieve)
        @this.send(:retrieve).should be_equal(q)
      end
      
      it "has an ID once it's ready" do
        wait_for_ready
        @this.id.should == 7
      end
      
      it "has data once it's ready" do
        wait_for_ready
        @this['slappy'].should == 17
      end
      
      it "can add a block with no parameters to execute on ready" do
        status = nil
        @this.on_ready {status = :done}
        status.should be_nil
        wait_for_ready
        status.should == :done
      end
      
      
      it "can add a block with the document to execute on ready" do
        id = nil
        @this.on_ready {|data| id = data.id}
        wait_for_ready
        id.should == 7
      end
      
      it "can add a block with the document and the event handler to execute on ready" do
        too, collection = nil, nil
        @this.on_ready {|doc, querist| too = doc['too']; collection = querist.collection}
        wait_for_ready
        too.should == :tar
        collection.should == @collection
      end
      
      it "can add a block to execute on failure" do
        class TrivialError < StandardError; end
        
        error = nil
        @this.on_ready {|doc, querist| querist.fail TrivialError.new "This should fail!"}
        @this.on_error {|e| error = e}
        wait_for_ready
        ->{raise error}.should raise_error(TrivialError, "This should fail!")
      end
    end
    
    describe "refreshing" do
      before(:each) do
        @verifier_collection.insert '_id' => 7, foo: 'bar', too: :tar, slappy: 17
        @this = @collection.document 7
        wait_for_ready
        @this['too'].should == :tar
        @verifier_collection.update({'_id' => 7}, {'$set' => {'too' => :car}})
      end
      
      describe "asynchronously" do
        it "returns immediately" do
          @this.refresh!
          @this.should_not be_ready
        end
        
        it "returns the document" do
          d = @this.refresh!
          d.should be_equal(@this)
        end
        
        it "is eventually ready" do
          @this.refresh!
          wait_for_ready
          @this.should be_ready
        end
        
        it "updates the data when ready" do
          @this.refresh!
          wait_for_ready
          @this['too'].should == :car
        end
        
        it "can return a clone instead of the document itself" do
          d = @this.refresh! clone: true
          d.should_not be_equal(@this)
        end
          
        it "can refresh periodically" do
          d = @this.refresh! periodic: 1
          sleep(1.2)
          wait_for_ready
          @verifier_collection.update({'_id' => 7}, {'$set' => {'too' => 'war'}})
          @this['too'].should == :car
          sleep(1.2)
          wait_for_ready
          @this['too'].should == 'war'
        end
        
        it "takes a block" do
          result = nil
          @this.refresh! {|doc| result = doc['too']}
          wait_for_ready
          result.should == :car
        end

        it "can refresh periodically with a block" do
          result = nil
          @this.refresh!(periodic: 1) {|doc| result = doc['too']}
          sleep(1.2)
          @verifier_collection.update({'_id' => 7}, {'$set' => {'too' => 'war'}})
          result.should == :car
          sleep(1.2)
          wait_for_ready
          result.should == 'war'
        end
      end
        
      describe "synchronously" do
        it "returns when it's ready" do
          @this.refresh
          @this.should be_ready
        end
        
        it "returns the document" do
          d = @this.refresh
          d.should be_equal(@this)
        end
        
        it "updates the data" do
          @this.refresh
          @this['too'].should == :car
        end
      end
    end
    
  end
end