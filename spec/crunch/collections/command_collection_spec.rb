require_relative '../../spec_helper'

module Crunch
  describe CommandCollection do
    before(:each) do
      @database = stub "Database", name: 'TestDB'
      @this = CommandCollection.spawn(@database) {|db| @database = db, @name = '$cmd', @full_name = "#{db}.$cmd"}
    end
    
    it "knows its name" do
      @this.name.should == '$cmd'
    end
    
    it "knows its full name" do
      @this.full_name.should == 'TestDB.$cmd'
    end
    
    describe "getnonce" do
      before(:each) do
        @message = QueryMessage.new(@this, query: {getnonce: 1}, limit: 1)
        @database.stubs(:<<).with(@message.deliver).returns(true)
        @this << [:document, {"nonce" => "76a48653192997e6", "ok" => 1}]
      end
      
      it "sends a query to the database" do
        @database.expects(:<<).with(@message.deliver)
        @this.getnonce
      end
      
      it "returns a number" do
        @this.getnonce.should == "76a48653192997e6"
      end
    end
  end
end