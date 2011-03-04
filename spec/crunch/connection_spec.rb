require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Connection do
    before(:each) do
      @db = Database.connect 'crunch_test', min_connections: 1, max_connections: 1, heartbeat: 0.01
      tick and @this = @db.connections.first
    end
    
    it "knows its database" do
      @this.database.should == @db
    end
    
    it "knows its status" do
      @this.status.should == :active
    end
  end
end