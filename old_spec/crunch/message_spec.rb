require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  
  describe Message do
    before(:each) do
      @this = Message.new
    end
    
    behaves_like "a Message"
    
    it "has a fixed body" do
      @this.body.should == "To sit in sullen silence...\x00"
    end
   
  end
end