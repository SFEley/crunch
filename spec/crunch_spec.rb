require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Crunch do

  describe "utility methods" do
    describe "- oid" do
      it "converts strings to BSON::ObjectIDs" do
        this = Crunch.oid('4c2b91d33f1651039f000001')
        this.should be_a(BSON::ObjectID)
        this.generation_time.to_i.should == 1277923795  # 2010-06-30 18:49:55 UTC
      end
      
      it "returns a current BSON::ObjectID if no parameters are given" do
        this = Crunch.oid
        this.should be_a(BSON::ObjectID)
        this.generation_time.to_i.should be_close(Time.now.to_i, 1)
      end
    end
  end
end
