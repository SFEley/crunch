require_relative '../../spec_helper'
require_relative '../../shared_examples/message'

module Crunch
  describe QueryMessage do
    FOOBAR = "\x12\x00\x00\x00\x0Efoo\x00\x04\x00\x00\x00bar\x00\x00" # Serialized by BSON
    FIELDHASH = " \x00\x00\x00\x10_id\x00\x01\x00\x00\x00\x10foo\x00\x01\x00\x00\x00\x10zoo\x00\x01\x00\x00\x00\x00"
    
    before(:each) do
      @collection = stub full_name: 'TestDB.TestCollection'
      
      @this = QueryMessage.new(@collection, 
                                query: {foo: :bar},
                                fields: [:foo, 'zoo'],
                                skip: 11,
                                limit: 50)
    end
    
    it_should_behave_like "a Message"

    it "requires a collection" do
      ->{QueryMessage.new}.should raise_error(ArgumentError)
    end

    it "knows its collection name" do
      @this.collection_name.should == "TestDB.TestCollection"
    end
    
    
    it "can take a query on creation" do
      @this.query.should == {foo: :bar}
    end
    
    it "can take a query after the fact" do
      @this.query = {too: :tar}
      @this.query.should == {too: :tar}
    end
    
    it "can modify the query after the fact" do
      @this.query.merge! zoo: :zar
      @this.query.should == {foo: :bar, zoo: :zar}
    end
    
    it "can take a field list on creation" do
      @this.fields.should == [:foo, 'zoo']
    end
    
    it "can take a field list after the fact" do
      @this.fields = [:hi]
      @this.fields.should == [:hi]
    end
    
    it "can modify the field list after the fact" do
      @this.fields << :ho
      @this.fields.should == [:foo, 'zoo', :ho]
    end
    
    it "defaults skipping to 0" do
      that = QueryMessage.new(@collection)
      that.skip.should == 0
    end
    
    it "can take a skip parameter on creation" do
      @this.skip.should == 11
    end
    
    it "can take a skip parameter after the fact" do
      @this.skip = 19
      @this.skip.should == 19
    end
    
    it "defaults the limit to 0" do
      that = QueryMessage.new(@collection)
      that.limit.should == 0
    end
    
    it "can take a limit parameter on creation" do
      @this.limit.should == 50
    end
    
    it "can take a limit parameter after the fact" do
      @this.limit = 17
      @this.limit.should == 17
    end
    
    describe "body" do
      it "starts with 0 for no options" do
        @this.body[0..3].unpack('V').first.should == 0
      end
      
      it "contains the collection name" do
        @this.body[4..25].should == "TestDB.TestCollection\x00"
      end
      
      it "contains the skip count" do
        @this.body[26..29].unpack('V').first.should == 11
      end
      
      it "contains the limit" do
        @this.body[30..33].unpack('V').first.should == 50
      end
      
      it "contains the query document" do
        @this.body[34..51].should == FOOBAR
      end
        
      it "contains the field list" do
        @this.body[52..83].should == FIELDHASH
      end
      
      it "contains no field list if no fields were defined" do
        @this.fields = nil
        @this.body.length.should == 52
      end
      
      it "contains no field list if the fields array is empty" do
        @this.fields = []
        @this.body.length.should == 52
      end
    end
    
  end
    
end