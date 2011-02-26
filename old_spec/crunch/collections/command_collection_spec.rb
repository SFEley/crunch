require_relative '../../spec_helper'

module Crunch
  describe CommandCollection do
    before(:each) do
      @database = stub "Database", name: 'crunch_test'
      @this = CommandCollection.send(:new, @database)
    end
    
    it "knows its name" do
      @this.name.should == '$cmd'
    end
    
    it "knows its full name" do
      @this.full_name.should == 'crunch_test.$cmd'
    end
    
    describe "getnonce" do
      before(:each) do
        @database.stubs(:<<).with(instance_of(QueryMessage)).returns(true)
        # @this << [:document, {"nonce" => "76a48653192997e6", "ok" => 1}]
      end
      
      it "sends a query to the database" do
        pending
        @database.expects(:<<).with(instance_of(QueryMessage)).returns(true)
        @this.getnonce
      end
      
      it "returns a number" do
        pending
        @this.getnonce.should == "76a48653192997e6"
      end
    end
  end
end