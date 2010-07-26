require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Document do
    BSON_STRING = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    BSON_WITH_ID = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    
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
      pending
      @this['_id'] = 7  # For predictability
      "#{@this}".should == BSON_WITH_ID
    end
    
    it "knows when it's ready" do
      @this.should be_ready
    end      

    describe "querying" do
      before(:each) do
        @verifier_collection.insert '_id' => 7, foo: 'bar', too: :tar, slappy: 17
        @this = Document.send(:new, @collection, id: 7)
        Thread.current.priority = 15  # Try to make sure EM doesn't complete before we do our in-process tests
      end
      
      def wait_for_ready
        increment = 0.0005
        sleep(increment *= 2) until @this.ready? || increment > 5
      end
      
      it "knows it isn't ready" do
        @this.should_not be_ready
      end
      
      it "can begin a retrieval" do
        @this.retrieve.should be_a(DocumentQuerist)
      end
      
      it "returns the same querist on each retrieval if one's in process" do
        # Do our best to make sure the query doesn't return before we do our comparisons
        q = @this.retrieve
        @this.retrieve.should be_equal(q)
      end
      
      it "doesn't say it's ready until it's ready" do
        @this.retrieve
        @this.should_not be_ready
      end
      
      it "has an ID once it's ready" do
        @this.retrieve
        wait_for_ready
        @this.id.should == 7
      end
      
      it "has data once it's ready" do
        @this.retrieve
        wait_for_ready
        @this['slappy'].should == 17
      end
        
      
    
      
      after(:each) do
        Thread.current.priority = 0
      end
    end
  end
end