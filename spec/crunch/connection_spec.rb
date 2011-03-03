require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Connection do
    before(:each) do
      @db = Database.connect 'crunch_test'
      tick and @this = @db.connections.first
    end
    
    it "knows its database" do
      @this.database.should == @db
    end
  end
end