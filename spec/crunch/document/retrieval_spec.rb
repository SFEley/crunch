require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe Document, "retrieval" do
    before(:each) do
      @database = Database.connect 'crunch_test'
      @collection = @database.collection 'TestCollection'
      @verifier_collection.insert '_id' => 17, 'foo' => 'bar', 'soo' => 'sar', 'floaty' => 11.59
    end
    
    it "requires a database" do
      ->{Document.retrieve}.should raise_error(ArgumentError)
    end

    it "requires a collection" do
      ->{Document.retrieve @database}.should raise_error(ArgumentError)
    end
    
    it "take an id" do
      this = Document.retrieve 17
      this['foo'].should == 'bar'
    end
    
    
    describe "from the database" do

      it "requires a collection" do
        ->{@database.document 17}.should raise_error(ArgumentError)
      end
      
      describe "(synchronous)" do
        it "returns a document if one is found" do
          @database.document('TestCollection', 17).should be_a(Document)
        end
        
        it "returns nil if nothing is found" do
          @database.document('TestCollection', 'bah!').should be_nil
        end
      end
        
    end
    
    describe "from a collection" do
      before(:each) do
        @collection = @database.collection 'TestCollection'
      end
      
      describe "(synchronous)" do
        it "returns a document if one is found" do
          @collection.document(17).should be_a(Document)
        end
        
        it "returns nil if nothing is found" do
          @collection.document('bah!').should be_nil
        end
      end
    end
    
  
  end
end