require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Fieldset do
    BSON_STRING = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
    before(:each) do
      @this = Fieldset.new(foo: 'bar', too: :tar, slappy: 17)
    end
    
    it "takes a hash as its values" do
      @this.values.should == ['bar', :tar, 17]
    end
    
    it "stringifies its keys" do
      @this.keys.should == ['foo', 'too', 'slappy']
    end
    
    it "stringifies new keys when added" do
      @this[:yoo] = :yar
      @this[5] = 5
      @this.should include({'yoo' => :yar, '5' => 5}) 
    end
    
    it "stringifies new keys when merged" do
      @this.merge! :cool => :car
      @this.should include("cool" => :car)
    end
    
    it "takes a binary string as its values" do
      this = Fieldset.new(BSON_STRING)
      this.should == {"foo" => 'bar', "too" => :tar, "slappy" => 17}
    end
    
    it "takes a ByteBuffer as its values" do
      this = Fieldset.new(BSON::ByteBuffer.new(BSON_STRING))
      this.should == {"foo" => 'bar', "too" => :tar, "slappy" => 17}
    end
    
    it "complains if anything else is given" do
      ->{this = Fieldset.new(5)}.should raise_error(FieldsetError)
    end
    
    it "knows how to serialize itself" do
      "#{@this}".should == BSON_STRING
    end
    
    
  end
end