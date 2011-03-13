require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Crunch do
  describe "utility methods" do
    it "defines the BSON zero as a convenience" do
      Crunch::ZERO.should == "\x00\x00\x00\x00"
    end
    
    describe "- oid" do
      it "converts strings to BSON::ObjectIds" do
        pending
        this = Crunch.oid('4c2b91d33f1651039f000001')
        this.should be_a(Crunch::BSON::ObjectID)
        this.timestamp.to_i.should == 1277923795  # 2010-06-30 18:49:55 UTC
      end
      
      it "returns a current BSON::ObjectId if no parameters are given" do
        pending
        this = Crunch.oid
        this.should be_a(Crunch::BSON::ObjectID)
        this.timestamp.to_i.should be_within(1).of(Time.now.to_i)
      end
    end
    

  end
end
