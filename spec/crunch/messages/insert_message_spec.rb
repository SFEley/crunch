require_relative '../../spec_helper'
require_relative '../../shared_examples/message'

module Crunch
  describe InsertMessage do
    BSON_DOC = "/\x00\x00\x00\x10_id\x00\x11\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x01num\x00\xCD\xCC\xCC\xCC\xCC\xCC\x14@\bbool\x00\x00\x00"
    
    before(:each) do
      @database = Database.connect 'crunch_test'
      @collection = @database.collection 'TestCollection'
      @fieldset = Fieldset.new '_id' => 17, foo: 'bar', 'num' => 5.2, 'bool' => false
      @this = InsertMessage.new(@collection, @fieldset)
    end
    
    it_should_behave_like "a Message"

    it "requires a collection" do
      ->{InsertMessage.new}.should raise_error(ArgumentError)
    end
    
    it "requires a fieldset" do
      ->{InsertMessage.new @collection}.should raise_error(ArgumentError)
    end
        
    it "can modify the fieldset after the fact" do
      @this.fieldset.merge! zoo: :zar
      @this.fieldset.should == {'_id' => 17, 'foo' => 'bar', 'num' => 5.2, 'bool' => false, 'zoo' => :zar}
    end
    
    it "raises an error if the fieldset doesn't have an _id" do
      @this.fieldset.delete('_id')
      ->{@this.deliver}.should raise_error(MessageError, /_id field/)
    end
    
    describe "body" do
      it "starts with 0 for no options" do
        @this.body[0..3].unpack('V').first.should == 0
      end
      
      it "contains the collection name" do
        @this.body[4..30].should == "crunch_test.TestCollection\x00"
      end
      
      it "contains the document" do
        @this.body[31..79].should == BSON_DOC
      end
    end
  end    
end