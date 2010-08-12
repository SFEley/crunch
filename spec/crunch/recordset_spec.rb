require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Recordset do
    before(:each) do
      @bson_string = "4\x00\x00\x00\x10_id\x00\a\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00:\x00\x00\x00\x0E_id\x00\x05\x00\x00\x00argh\x00\x0Efoo\x00\x06\x00\x00\x00rebar\x00\x02too\x00\x04\x00\x00\x00far\x00\x10happy\x00\xFB\xFF\xFF\xFF\x00"
    end
    
    describe "from binary data" do
      it "requires a count" do
        ->{Recordset.new}.should raise_error(ArgumentError)
      end

      it "requires a data stream" do
        ->{Recordset.new(5)}.should raise_error(RecordsetError)
      end
    end
    
    describe "from an array" do
      it "should description" do
        fail
      end
    end
    
  end
end