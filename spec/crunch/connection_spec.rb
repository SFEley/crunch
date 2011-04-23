require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Connection do
    before(:all) do
      # Start a dummy server to listen
      Thread.new do
        EM.run do
          EM.start_server "0.0.0.0", $DUMMY_PORT, DummyServer
        end
      end
    end     
      
    before(:each) do
      @db = Database.connect 'crunch_test', port: $DUMMY_PORT,
          min_connections: 1, max_connections: 1, heartbeat: 0.01
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
    
    it "sends non-shutdown messages to the server" do
      req = Request.new(message: "Ping!")
      tick {@db << req}
      sleep 0.2   # Stupid timing delays...
      DummyServer.received.should == "#{req}"
    end
    
    it "does not send shutdown messagses to the server" do
      tick {@db << ShutdownRequest.new}
      sleep 0.2
      DummyServer.should be_empty
    end
    
    it "can receive replies from the server" do
      pending
    end
    
    after(:each) do
      # Clear the global Databases hash
      Database.class_variable_set(:@@databases, {})
      DummyServer.clear
    end
    
    after(:all) do
      # Stop our dummy server
      if EM.reactor_running?
        EM.run {EM.stop_event_loop}
        Thread.pass while EM.reactor_running?
      end
    end
  end
end