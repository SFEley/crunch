#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'
require 'digest/md5'

module Crunch
  module BSON
    describe "- binary method" do
      it "handles an empty binary string" do
        BSON.binary('').bin.should == "\x00\x00\x00\x00\x00"
      end
      
      it "does NOT handle nil" do
        ->{BSON.binary(nil)}.should raise_error(BSONError, /binary string/)
      end
      
      it "does NOT convert other types" do
        ->{BSON.binary(3.14)}.should raise_error(BSONError, /binary string/)
      end
      
      it "returns a BSON::Binary object" do
        BSON.binary("}\x99$\x00").should be_a(Binary)
      end
      
      it "adds the subtype and length" do
        BSON.binary("}\x99$\x00").bin.should == "\x04\x00\x00\x00\x00}\x99$\x00"
      end  
    end
    
    describe Binary do
      before(:each) do
        @pi = "\x1F\x85\xEBQ\xB8\x1E\t@"  # 3.14 as an encoded float
        
      end
      
      it "can take a data string" do
        Binary.new(@pi).bin.should == "\x08\x00\x00\x00\x00#{@pi}"
      end
      
      it "knows its data" do
        Binary.new(@pi).data.should == @pi
      end
      
      it "returns its data as a string" do
        Binary.new(@pi).to_s.should == @pi
      end
      
      it "can take a Function type" do
        Binary.new(@pi, subtype: Binary::FUNCTION).bin.should == "\x08\x00\x00\x00\x01#{@pi}"
      end
      
      it "can take an 'old' binary type" do
        b = Binary.new("\x08\x00\x00\x00#{@pi}", subtype: Binary::OLD)
        b.bin.should == "\x0C\x00\x00\x00\x02\x08\x00\x00\x00#{@pi}"
        b.data.should == @pi
      end
      
      it "can take a UUID type" do
        Binary.new(@pi, subtype: Binary::UUID).bin.should == "\x08\x00\x00\x00\x03#{@pi}"
      end
      
      it "can take an MD5 type" do
        md5 = Digest::MD5.new('foo')
        Binary.new(md5.digest, subtype: Binary::MD5).bin.should == "\x10\x00\x00\x00\x05\xD4\x1D\x8C\xD9\x8F\x00\xB2\x04\xE9\x80\t\x98\xEC\xF8B~"
      end
    
      it "can take a user defined type" do
        Binary.new(@pi, subtype: Binary::USER).bin.should == "\x08\x00\x00\x00\x80#{@pi}"
      end
      
      it "can take the length" do
        Binary.new(@pi, subtype: Binary::GENERIC, length: "\x08\x00\x00\x00").bin.should == "\x08\x00\x00\x00\x00#{@pi}"
      end
      
      it "can return a full element" do
        Binary.new("\x1F\x85\xEBQ\xB8\x1E\t@").element.should == [5, 13, "\x08\x00\x00\x00\x00\x1F\x85\xEBQ\xB8\x1E\t@"]
      end
        
    end
      
  end
end