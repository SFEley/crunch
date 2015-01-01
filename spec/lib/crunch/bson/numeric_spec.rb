#encoding: BINARY

require 'spec_helper'

module Crunch
  describe BSON do
    describe "- from_int" do
      it "converts zero" do
        BSON.from_int(0).should == "\x00\x00\x00\x00"
      end

      it "converts 1" do
        BSON.from_int(1).should == "\x01\x00\x00\x00"
      end

      it "converts -1" do
        BSON.from_int(-1).should == "\xFF\xFF\xFF\xFF"
      end

      it "converts 100" do
        BSON.from_int(100).should == "\x64\x00\x00\x00"
      end

      it "converts -100" do
        BSON.from_int(-100).should == "\x9C\xFF\xFF\xFF"
      end

      it "converts positive numbers just below the 32-bit boundary" do
        BSON.from_int(2147483647).should == "\xFF\xFF\xFF\x7F"
      end

      it "converts negative numbers just below the 32-bit boundary" do
        BSON.from_int(-2147483648).should == "\x00\x00\x00\x80"
      end

      it "converts the positive 32-bit boundary as 64 bits" do
        BSON.from_int(2147483648).should == "\x00\x00\x00\x80\x00\x00\x00\x00"
      end

      it "converts the negative 32-bit boundary as 64 bits" do
        BSON.from_int(-2147483649).should == "\xFF\xFF\xFF\x7F\xFF\xFF\xFF\xFF"
      end

      it "converts positive numbers just below the 64-bit boundary" do
        BSON.from_int(9223372036854775807).should == "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F"
      end

      it "converts negative numbers just below the 64-bit boundary" do
        BSON.from_int(-9223372036854775808).should == "\x00\x00\x00\x00\x00\x00\x00\x80"
      end

      it "returns short numbers as 4 bytes if specified" do
        BSON.from_int(100, length: 4).should == "\x64\x00\x00\x00"
      end

      it "returns short numbers as 8 bytes if specified" do
        BSON.from_int(100, length: 8).should == "\x64\x00\x00\x00\x00\x00\x00\x00"
      end

      it "returns short numbers as some ridiculous length if specified" do
        BSON.from_int(100, length: 16).should == "\x64\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      end

      it "throws an error if overflowing on positive integers" do
        ->{BSON.from_int(2147483648, length: 4)}.should raise_error(Crunch::CrunchError, /overflow/)
      end

      it "throws an error if underflowing on negative integers" do
        ->{BSON.from_int(-2147483649, length: 4)}.should raise_error(Crunch::CrunchError, /overflow/)
      end
    end

    describe "- to_int" do
      it "converts zero as 4 bytes" do
        BSON.to_int("\x00\x00\x00\x00").should == 0
      end

      it "converts 1" do
        BSON.to_int("\x01\x00\x00\x00").should == 1
      end

      it "converts -1" do
        BSON.to_int("\xFF\xFF\xFF\xFF").should == -1
      end

      it "converts 100" do
        BSON.to_int("\x64\x00\x00\x00").should == 100
      end

      it "converts -100" do
        BSON.to_int("\x9C\xFF\xFF\xFF").should == -100
      end

      it "converts positive numbers just below the 32-bit boundary" do
        BSON.to_int("\xFF\xFF\xFF\x7F").should == 2147483647
      end

      it "converts negative numbers just below the 32-bit boundary" do
        BSON.to_int("\x00\x00\x00\x80").should == -2147483648
      end

      it "converts the positive 32-bit boundary" do
        BSON.to_int("\x00\x00\x00\x80\x00\x00\x00\x00").should == 2147483648
      end

      it "converts the negative 32-bit boundary" do
        BSON.to_int("\xFF\xFF\xFF\x7F\xFF\xFF\xFF\xFF").should == -2147483649
      end

      it "converts positive numbers just below the 64-bit boundary" do
        BSON.to_int("\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F").should == 9223372036854775807
      end

      it "converts negative numbers just below the 64-bit boundary" do
        BSON.to_int("\x00\x00\x00\x00\x00\x00\x00\x80").should == -9223372036854775808
      end
    end

    describe "- from_float" do
      it "converts zero" do
        BSON.from_float(0.0).should == "\x00\x00\x00\x00\x00\x00\x00\x00"
      end

      it "converts one" do
        BSON.from_float(1.0).should == "\x00\x00\x00\x00\x00\x00\xF0?"
      end

      it "converts negative one" do
        BSON.from_float(-1.0).should == "\x00\x00\x00\x00\x00\x00\xF0\xBF"
      end

      it "converts Pi" do
        BSON.from_float(Math::PI).should == "\x18-DT\xFB!\t@"
      end

      it "converts the largest value" do
        BSON.from_float(Float::MAX).should == "\xFF\xFF\xFF\xFF\xFF\xFF\xEF\x7F"
      end

      it "converts the smallest value" do
        BSON.from_float(Float::MIN).should == "\x00\x00\x00\x00\x00\x00\x10\x00"
      end

      it "converts not-a-number" do
        BSON.from_float(0/0.0).should == "\x00\x00\x00\x00\x00\x00\xF8\xFF"
      end

      it "converts positive infinity" do
        BSON.from_float(1/0.0).should == "\x00\x00\x00\x00\x00\x00\xF0\x7F"
      end

      it "converts negative infinity" do
        BSON.from_float(-0.1/0.0).should == "\x00\x00\x00\x00\x00\x00\xF0\xFF"
      end


    end


   describe "- to_float" do
     it "converts zero" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\x00\x00").should == 0.0
     end

     it "converts one" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\xF0?").should == 1.0
     end

     it "converts negative one" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\xF0\xBF").should == -1.0
     end

     it "converts Pi" do
       BSON.to_float("\x18-DT\xFB!\t@").should == Math::PI
     end

     it "converts the largest value" do
       BSON.to_float("\xFF\xFF\xFF\xFF\xFF\xFF\xEF\x7F").should == Float::MAX
     end

     it "converts the smallest value" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\x10\x00").should == Float::MIN
     end

     it "converts not-a-number" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\xF8\xFF").should be_nan
     end

     it "converts positive infinity" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\xF0\x7F").should == (100/0.0)
     end

     it "converts negative infinity" do
       BSON.to_float("\x00\x00\x00\x00\x00\x00\xF0\xFF").should == (-100.0/0)
     end


   end

  end
end
