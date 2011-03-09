require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Crunch do
  describe "utility methods" do
    describe "- oid" do
      it "converts strings to BSON::ObjectIds" do
        this = Crunch.oid('4c2b91d33f1651039f000001')
        this.should be_a(BSON::ObjectId)
        this.generation_time.to_i.should == 1277923795  # 2010-06-30 18:49:55 UTC
      end
      
      it "returns a current BSON::ObjectId if no parameters are given" do
        this = Crunch.oid
        this.should be_a(BSON::ObjectId)
        this.generation_time.to_i.should be_within(1).of(Time.now.to_i)
      end
    end
    
    describe "- int_to_bson" do
      it "converts zero" do
        Crunch.int_to_bson(0).should == "\x00\x00\x00\x00"
      end
      
      it "converts 1" do
        Crunch.int_to_bson(1).should == "\x01\x00\x00\x00"
      end
      
      it "converts -1" do
        Crunch.int_to_bson(-1).should == "\xFF\xFF\xFF\xFF"
      end
      
      it "converts 100" do
        Crunch.int_to_bson(100).should == "\x64\x00\x00\x00"
      end
      
      it "converts -100" do
        Crunch.int_to_bson(-100).should == "\x9C\xFF\xFF\xFF"
      end
      
      it "converts positive numbers just below the 32-bit boundary" do
        Crunch.int_to_bson(2147483647).should == "\xFF\xFF\xFF\x7F"
      end
      
      it "converts negative numbers just below the 32-bit boundary" do
        Crunch.int_to_bson(-2147483648).should == "\x00\x00\x00\x80"
      end
      
      it "converts the positive 32-bit boundary as 64 bits" do
        Crunch.int_to_bson(2147483648).should == "\x00\x00\x00\x80\x00\x00\x00\x00"
      end

      it "converts the negative 32-bit boundary as 64 bits" do
        Crunch.int_to_bson(-2147483649).should == "\xFF\xFF\xFF\x7F\xFF\xFF\xFF\xFF"
      end

      it "converts positive numbers just below the 64-bit boundary" do
        Crunch.int_to_bson(9223372036854775807).should == "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F"
      end
      
      it "converts negative numbers just below the 64-bit boundary" do
        Crunch.int_to_bson(-9223372036854775808).should == "\x00\x00\x00\x00\x00\x00\x00\x80"
      end
      
      it "returns short numbers as 4 bytes if specified" do
        Crunch.int_to_bson(100, length: 4).should == "\x64\x00\x00\x00"
      end

      it "returns short numbers as 8 bytes if specified" do
        Crunch.int_to_bson(100, length: 8).should == "\x64\x00\x00\x00\x00\x00\x00\x00"
      end
      
      it "throws an error if overflowing on positive integers beyond 4 byte length" do
        ->{Crunch.int_to_bson(2147483648, length: 4)}.should raise_error(Crunch::CrunchError, /overflow/)
      end
      
      it "throws an error if underflowing on negative integers beyond 4 byte length" do
        ->{Crunch.int_to_bson(-2147483649, length: 4)}.should raise_error(Crunch::CrunchError, /underflow/)
      end

      it "throws an error if overflowing on positive integers beyond 8 bytes" do
        ->{Crunch.int_to_bson(9223372036854775808)}.should raise_error(Crunch::CrunchError, /overflow/)
      end
      
      it "throws an error if underflowing on negative integers beyond 8 bytes" do
        ->{Crunch.int_to_bson(-9223372036854775809)}.should raise_error(Crunch::CrunchError, /underflow/)
      end

    end

    describe "- bson_to_int" do
      it "throws an error if not 4 or 8 bytes" do
        ->{Crunch.bson_to_int("\x00\x00\x00")}.should raise_error(Crunch::CrunchError, /4 or 8 bytes/)
        ->{Crunch.bson_to_int("\x00\x00\x00\x00\x00")}.should raise_error(Crunch::CrunchError, /4 or 8 bytes/)
        ->{Crunch.bson_to_int("\x00\x00\x00\x00\x00\x00\x00\x00\x00")}.should raise_error(Crunch::CrunchError, /4 or 8 bytes/)
        ->{Crunch.bson_to_int('')}.should raise_error(Crunch::CrunchError, /4 or 8 bytes/)
      end
        
      it "converts zero as 4 bytes" do
        Crunch.bson_to_int("\x00\x00\x00\x00").should == 0
      end
      
      it "converts 1" do
        Crunch.bson_to_int("\x01\x00\x00\x00").should == 1
      end
      
      it "converts -1" do
        Crunch.bson_to_int("\xFF\xFF\xFF\xFF").should == -1
      end
      
      it "converts 100" do
        Crunch.bson_to_int("\x64\x00\x00\x00").should == 100
      end
      
      it "converts -100" do
        Crunch.bson_to_int("\x9C\xFF\xFF\xFF").should == -100
      end
      
      it "converts positive numbers just below the 32-bit boundary" do
        Crunch.bson_to_int("\xFF\xFF\xFF\x7F").should == 2147483647
      end
      
      it "converts negative numbers just below the 32-bit boundary" do
        Crunch.bson_to_int("\x00\x00\x00\x80").should == -2147483648
      end
      
      it "converts the positive 32-bit boundary" do
        Crunch.bson_to_int("\x00\x00\x00\x80\x00\x00\x00\x00").should == 2147483648
      end

      it "converts the negative 32-bit boundary" do
        Crunch.bson_to_int("\xFF\xFF\xFF\x7F\xFF\xFF\xFF\xFF").should == -2147483649
      end
      
    end


  end
end
