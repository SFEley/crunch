require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Crunch do
  describe "utility methods" do
    it "defines the BSON zero as a convenience" do
      Crunch::ZERO.should == "\x00\x00\x00\x00"
    end
    
    describe "- oid" do
      it "converts strings to BSON::ObjectIds" do
        this = Crunch.oid('4c2b91d33f1651039f000001')
        this.should be_a(BSON::ObjectID)
        this.generation_time.to_i.should == 1277923795  # 2010-06-30 18:49:55 UTC
      end
      
      it "returns a current BSON::ObjectId if no parameters are given" do
        this = Crunch.oid
        this.should be_a(BSON::ObjectID)
        this.generation_time.to_i.should be_within(1).of(Time.now.to_i)
      end
    end
    
    describe "- Counter" do
      it "increments every time it's called" do
        Crunch::Counter.resume.should == Crunch::Counter.resume - 1
      end
      
      #### Commented out for being VERY SLOW!
      # it "rolls over after incrementing to the signed 24-bit maximum" do
      #   this = Crunch::Counter.resume until this == 8388607
      #   Crunch::Counter.resume.should == 0
      #   Crunch::Counter.resume.should == 1
      # end
    end

  end
end
