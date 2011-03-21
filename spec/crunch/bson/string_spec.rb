#encoding: UTF-8
require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe BSON do
    describe "- cstring method" do
      it "handles an empty string" do
        BSON.cstring('').should == "\x00"
      end
      
      it "handles a longer string" do
        BSON.cstring('I am Henry the Eighth I am').should == "I am Henry the Eighth I am\x00"
      end
      
      it "is UTF-8 encoded" do
        foo = "ol\xE9".force_encoding('ISO-8859-1')
        BSON.cstring(foo).should == "ol\xC3\xA9\x00".force_encoding('UTF-8')
        BSON.cstring(foo).encoding.should == Encoding::UTF_8
      end
      
      it "converts other types to strings" do
        BSON.cstring(:bar).should == "bar\x00"
      end
      
      it "handles nil" do
        BSON.cstring(nil).should == "\x00"
      end
      
      it "strips other nulls from the string" do
        BSON.cstring("He\x00ll\x00o").should == "Hello\u0000"
      end
      
      it "doesn't try to encode if we tell it the string is normalized" do
        foo = "ol\xE9".force_encoding(Encoding::BINARY) 
        cstring = BSON.cstring(foo, normalized: true)
        cstring.should == "#{foo}\x00"
        cstring.encoding.should == Encoding::BINARY
      end
    end
    
    describe "- from_string method" do
      it "handles an empty string" do
        BSON.from_string('').should == "\x01\x00\x00\x00\x00"
      end
      
      it "handles nil" do
        BSON.from_string(nil).should == "\x01\x00\x00\x00\x00"
      end
      
      it "converts other types to strings" do
        BSON.from_string(3.14).should == "\x05\x00\x00\x003.14\x00"
      end
      
      it "handles a longer string" do
        BSON.from_string("Ask not what you can do for your country…".force_encoding('UTF-8')).should == ",\x00\x00\x00Ask not what you can do for your country\xE2\x80\xA6\x00".force_encoding(Encoding::BINARY)
      end
      
      it "is binary encoded" do
        BSON.from_string("Ask not what you can do for your country…").encoding.should == Encoding::BINARY
      end
      
      it "converts strings to UTF-8" do
        foo = "ol\xE9".force_encoding('ISO-8859-1')
        BSON.from_string(foo).should == "\x05\x00\x00\x00ol\xC3\xA9\x00".force_encoding(Encoding::BINARY)
      end
      
      it "doesn't try to encode if we tell it the string is normalized" do
        foo = "ol\xE9".force_encoding('ISO-8859-1') 
        BSON.from_string(foo, normalized: true).should == "\x04\x00\x00\x00ol\xE9\x00".force_encoding('BINARY')
      end
      
    end
    
    describe "- from_binary method" do
      it "handles an empty binary string" do
        BSON.from_binary('').should == "\x00\x00\x00\x00\x00".force_encoding('BINARY')
      end
      
      it "does NOT handle nil" do
        ->{BSON.from_binary(nil)}.should raise_error(BSONError, /binary string/)
      end
      
      it "does NOT convert other types" do
        ->{BSON.from_binary(3.14)}.should raise_error(BSONError, /binary string/)
      end
      
      it "is binary encoded" do
        BSON.from_binary("}\x99$\x00".force_encoding('BINARY')).encoding.should == Encoding::BINARY
      end
      
      it "adds the subtype and length" do
        BSON.from_binary("}\x99$\x00".force_encoding('BINARY')).should == "\x04\x00\x00\x00\x00}\x99$\x00".force_encoding('BINARY')
      end
      
    end
    
  end
end