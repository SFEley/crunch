require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe Document, "retrieval" do
    before(:each) do
      @database = Database.connect 'crunch_test'
      @verifier_collection.insert '_id' => 17, 'foo' => 'bar', 'soo' => 'sar', 'floaty' => 11.59
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
  
  end
end