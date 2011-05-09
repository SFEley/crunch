require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Query do
    before(:all) do
      @db = Database.connect 'crunch_test'
      @coll = @db.collection 'test_collection'
    end
    
    describe "creation" do
      it "requires a collection on direct spawning" do
        ->{Query.new}.should raise_error(ArgumentError)
      end
      
      it "can be spawned from a collection"
      
      it "can be spawned from another Query"
    end
    
    describe "retrieval" do
      describe "options" do
        it "returns the entire collection if no options are given"
      end
      pending
    end
  
    describe "updating" do
      pending
    end
  end
end