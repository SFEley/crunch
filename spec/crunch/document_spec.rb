require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Document do
    BSON_STRING = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    BSON_WITH_ID = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    before(:each) do
      @database = Database.connect 'crunch_test'
      @this = Document.new @database, 'TestCollection', foo: 'bar', too: :tar, slappy: 17
    end
    
    it "requires a database" do
      ->{Document.new}.should raise_error(ArgumentError)
    end
    
    it "requires a collection" do
      ->{Document.new @database}.should raise_error(ArgumentError)
    end
    
    it "can take a collection name" do
      @this.collection.full_name.should == 'crunch_test.TestCollection'
    end
    
    it "can take a collection object" do
      that = Document.new @database, Collection.new(@database, 'TestCollection'), foo: 'bar'
      that.collection.full_name.should == 'crunch_test.TestCollection'
    end
    
    it "can take a Group and derive its collection" do
      pending
    end

    
    it "throws an error if you give it a collection object it doesn't understand" do
      ->{Document.new @database, []}.should raise_error(DocumentError, /requires a collection/)
    end
    
    it "knows its collection name" do
      @this.collection_name.should == 'crunch_test.TestCollection'
    end
    
    it "takes a hash as its own values" do
      @this.should include('foo' => 'bar', 'too' => :tar, 'slappy' => 17)
    end
    
    it "always has an ID" do
      @this['_id'].should be_a(BSON::ObjectID)
    end
    
    it "can take an ID as a parameter" do
      oid = Crunch.oid
      that = Document.new @database, 'TestCollection', foo: 'bar', id: oid
      that['_id'].should == oid
    end
      
    it "can take an ID of any form" do
      that = Document.new @database, 'TestCollection', foo: 'bar', too: :tar, slappy: 17, id: 'garbanzo'
      that['_id'].should == 'garbanzo'
    end
    
    it "takes a binary string as its values" do
      this = Document.new @database, 'TestCollection', BSON_STRING
      this.should include("foo" => 'bar', "too" => :tar, "slappy" => 17)
    end
    
    it "takes a ByteBuffer as its values" do
      this = Document.new @database, 'TestCollection', BSON::ByteBuffer.new(BSON_STRING)
      this.should include("foo" => 'bar', "too" => :tar, "slappy" => 17)
    end
    
    it "complains if anything else is given" do
      ->{this = Document.new @database, 'TestCollection', 5}.should raise_error(DocumentError)
    end
    
    it "knows how to serialize itself" do
      @this['_id'] = 7  # For predictability
      "#{@this}".should == BSON_WITH_ID
    end
    
    describe "messages" do
      
      it "should description" do
        
      end
    end
  end
end