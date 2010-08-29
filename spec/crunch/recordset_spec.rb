require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Recordset do
    before(:each) do
      @bson_string = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00:\x00\x00\x00\x0E_id\x00\x05\x00\x00\x00argh\x00\x0Efoo\x00\x06\x00\x00\x00rebar\x00\x02too\x00\x04\x00\x00\x00far\x00\x10happy\x00\xFB\xFF\xFF\xFF\x00"
    end
    
    describe "from binary data" do
      before(:each) do
        @this = Recordset.new 2, @bson_string
      end

      it "requires a count" do
        ->{Recordset.new}.should raise_error(ArgumentError)
      end

      it "requires a data stream" do
        ->{Recordset.new(5)}.should raise_error(RecordsetError)
      end
      
      it "converts each BSON document to a Fieldset" do
        @this.should have(2).records
        @this.each {|e| e.should be_a(Fieldset)}
      end
      
      it "preserves the data" do
        @this[0]['too'].should == :tar
        @this[1]['happy'].should == -5
      end
    end
    
    describe "from an array" do
      before(:each) do
        @array =  [ 
          {'_id' => 7, foo: 'bar', too: :tar, slappy: 17},
          {'_id' => :argh, foo: :rebar, too: 'far', happy: -5}
        ]
        @this = Recordset.new(@array)
      end
      it "converts each element to a Fieldset" do
        @this.each {|e| e.should be_a(Fieldset)}
        @this.first['slappy'].should == 17
        @this[1]['foo'].should == :rebar
      end
      it "knows its length" do
        @this.size.should == 2
      end
    end
    
  end
end