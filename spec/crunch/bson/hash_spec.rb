#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe BSON do
    describe "- from_hash method" do
      it "converts simple hashes" do
        this = {'hi' => 'ho', 'three' => 3}
        BSON.from_hash(this).should == "\e\x00\x00\x00\x02hi\x00\x03\x00\x00\x00ho\x00\x10three\x00\x03\x00\x00\x00\x00"
      end
      
      it "converts empty hashes" do
        BSON.from_hash({}).should == "\x05\x00\x00\x00\x00"
      end
      
    end
    
    describe "- from_element method" do
      it "returns three values" do
        foo = BSON.from_element("foo")
        foo.should have(3).elements
      end
      
      it "handles floats" do
        BSON.from_element(3.14).should == [1, 8, "\x1F\x85\xEBQ\xB8\x1E\t@"]
      end
      
      it "handles strings" do
        BSON.from_element("Yowza!").should == [2, 11, "\a\x00\x00\x00Yowza!\x00"]
      end
      
      it "handles hashes" do
        BSON.from_element('foo' => 1, 'bar' => 2).should == [3, 23, "\x17\x00\x00\x00\x10foo\x00\x01\x00\x00\x00\x10bar\x00\x02\x00\x00\x00\x00"]
      end
      
      it "handles 32-bit integers" do
        BSON.from_element(23892).should == [16, 4, "T]\x00\x00"]
      end
      
      it "handles 64-bit integers" do
        BSON.from_element(978058152744563660).should == [18, 8, "\xCC\xB3\x03<\xB5\xC2\x92\r"]
      end
      
      it "does not handle larger integers" do
        ->{BSON.from_element(45247506830213931574861552163)}.should raise_error(BSONError, /larger than/)
      end
    end
    
  end
end
