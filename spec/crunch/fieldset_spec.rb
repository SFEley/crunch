require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Fieldset do
    before(:each) do
      @bson_string = "+\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x0Etoo\x00\x04\x00\x00\x00tar\x00\x10slappy\x00\x11\x00\x00\x00\x00"
      @this = Fieldset.new(foo: 'bar', too: :tar, 'slappy' => 17)
    end
  
    it "can be initialized from a hash" do
      @this['slappy'].should == 17
    end
  
    it "is immutable" do
      ->{@this[:hi] = 'ho'}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't clear" do
      ->{@this.clear}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't delete" do
      ->{@this.delete(:foo)}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't delete_if" do
      ->{@this.delete_if {true}}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't merge!" do
      ->{@this.merge! zoo: :zar}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't rehash" do
      ->{@this.rehash}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't reject!" do
      ->{@this.reject! {true}}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't replace" do
      ->{@this.replace foo: 'car'}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't shift" do
      ->{@this.shift}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't store" do
      ->{@this.store :zoo, :zar}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "doesn't update" do
      ->{@this.update zoo: :zar}.should raise_error(FieldsetError, /immutable/)
    end
  
    it "can be initialized from a Fieldset" do
      that = @this
      that.should == @this
    end

    it "stringifies its keys" do
      @this.keys.should == ['foo', 'too', 'slappy']
    end

    it "stringifies number keys" do
      that = Fieldset.new(7 => 'Eleven')
      that['7'].should == 'Eleven'
    end
  
    it "returns BSON when asked for a string" do
      @this.to_s.should == @bson_string
    end
  
    it "returns a Hash when asked for one" do
      h = @this.to_hash
      h.class.should == Hash
      h['foo'].should == 'bar'
    end
  
      
    it "can be initialized from a BSON binary string" do
      this = Fieldset.new(@bson_string)
      this.should == {"foo" => 'bar', "too" => :tar, "slappy" => 17}
    end
  
    
    it "can take an array as its values (in which case each element receives a hash value of 1)" do
      this = Fieldset.new([:foo, 'bar', :blah])
      this.should == {'foo' => 1, 'bar' => 1, 'blah' => 1}
    end
  
    it "can be initialized from nil" do
      this = Fieldset.new
      this.should == {}
      this.to_s.should == "\x05\x00\x00\x00\x00"
    end
  
    it "complains if anything else is given" do
      ->{this = Fieldset.new(5)}.should raise_error(FieldsetError)
    end
  
    it "indicates its class when inspected" do
      @this.inspect.should =~ /Fieldset.*slappy/
    end
  
  end
end