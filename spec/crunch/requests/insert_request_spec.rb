require File.dirname(__FILE__) + '/../../spec_helper'

module Crunch
  describe InsertRequest do
    before(:each) do
      @sender = DummySender.new
      @doc = Fieldset.new foo: 'bar', 'yoo' => 'yar'
      @this = InsertRequest.new @sender, @doc
    end
    
    behaves_like "a Request"
    
    it "has a zero after the header 'for future use'" do
      @this.body[0..3].should == Crunch::ZERO
    end
    
    it "includes its collection name" do
      @this.body[4..29].should == "dummy_db.dummy_collection\x00"
    end
    
    it "can have one document" do
      @this.body[30..62].should == @doc.to_s
    end
      
    it "can have more documents" do
      doc2 = Fieldset.new 'zoo' => :zar, '500' => 'far'
      that = InsertRequest.new @sender, @doc, doc2
      that.body[30..-1].should == @doc.to_s + doc2.to_s
    end
  end
end