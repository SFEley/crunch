require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Connection do
    before(:each) do
      @db = Database.connect 'crunch_test', min_connections: 1, max_connections: 1, heartbeat: 0.01
      tick and @this = @db.connections.first
      @this.requests_processed.should == 0
    end
    
    it "knows its database" do
      @this.database.should == @db
    end
    
    it "knows its status" do
      @this.status.should == :active
    end
    
    it "gets a message off the queue" do
      r = Request.new(message: 'Test')
      tick {@db << r}
      @this.requests_processed.should == 1
      @this.last_request.should == r
    end
    
    it "continues to get messages" do
      tick {3.times {|i| @db << Request.new(message: i.to_s)}}
      @this.requests_processed.should == 3
      @this.last_request.body.should == "2\x00"   # Because it's 0-based
    end
    
    it "dies on a shutdown request" do
      @db.connections.should include(@this)
      tick {@db << ShutdownRequest.new}
      @this.status.should == :terminated
      sleep 0.2
      @db.connections.should_not include(@this)
    end
    
    
    after(:each) do
      # Clear the global Databases hash
      Database.class_variable_set(:@@databases, {})
    end

       
  end
end