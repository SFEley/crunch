require File.dirname(__FILE__) + '/../spec_helper'


module Crunch
  describe Database do
    # Stub class and utility method for it
    class DummyRequest < Crunch::Request
    end
    
    def request
      DummyRequest.new
    end
    
    describe ".connect method" do
      before(:each) do
        @this = Database.connect 'crunch_test'
      end
      
      it "is pointed at if you try to run .new" do
        ->{Database.new 'test'}.should raise_error(DatabaseError, /connect/)
      end
    
      it "returns an instance with .connect" do
        @this.should be_a(Database)
      end
    
      it "requires a name" do
        ->{Database.connect}.should raise_error(ArgumentError)
      end
      
      it "knows its name" do
        @this.name.should == 'crunch_test'
      end
      
      it "has a default host" do
        @this.host.should == 'localhost'
      end
      
      it "has a default port" do
        @this.port.should == 27017
      end
      
      it "has a default minimum connection count" do
        @this.min_connections.should == 1
      end
    
      it "has a default maximum connection count" do
        @this.max_connections.should == 10
      end
    
      it "has a default heartbeat" do
        @this.heartbeat.should == 1.0
      end
      
      it "returns the same instance given the same name, host, and port" do
        that = Database.connect 'crunch_test'
        that.object_id.should == @this.object_id
      end
    
      it "returns a different instance if a different name is given" do
        that = Database.connect 'crunchy_test'
        that.object_id.should_not == @this.object_id
      end
    
      it "returns a different instance if a different host is given" do
        that = Database.connect 'crunch_test', host: 'example.org'
        that.object_id.should_not == @this.object_id
      end
      
      it "returns a different instance if a different port is given" do
        that = Database.connect 'crunch_test', port: 1111
        that.object_id.should_not == @this.object_id
      end
      
      it "can reset the minimum connection count at new connection invocations" do
        that = Database.connect 'crunch_test', min_connections: 3
        @this.min_connections.should == 3
      end
      
      it "can reset the minimum connection count at runtime" do
        that = Database.connect 'crunch_test'
        that.min_connections = 2
        @this.min_connections.should == 2
      end
    
      it "can reset the maximum connection count at new connection invocations" do
        that = Database.connect 'crunch_test', max_connections: 5
        @this.max_connections.should == 5
      end
      
      it "can reset the maximum connection count at runtime" do
        that = Database.connect 'crunch_test'
        that.max_connections = 7
        @this.max_connections.should == 7
      end
    
      it "can reset the heartbeat at new connection invocations" do
        that = Database.connect 'crunch_test', heartbeat: 2.3
        @this.heartbeat.should == 2.3
      end
      
      it "can reset the heartbeat count at runtime" do
        that = Database.connect 'crunch_test'
        that.heartbeat = 0.1
        @this.heartbeat.should == 0.1
      end
    
      it "starts the event loop" do
        EventMachine.should be_reactor_running
      end
    end
    
    describe "request queue" do
      
      before(:each) do
        @this = Database.connect 'crunch_test'
      end

      it "starts with no requests" do
        @this.pending_count.should == 0
      end
      
      it "can accept requests" do
        tick {@this << request}
        @this.pending_count.should == 1
      end
      
      it "fails on a non-Request" do
        ->{@this << true}.should raise_error(DatabaseError, /Request/)
      end
      
      it "sets the begin time of the request" do
        r = request
        r.began.should be_nil
        tick {@this << r}
        r.began.should be_within(1).of(Time.now)
      end
      
      it "can be chained" do
        tick {@this << request << request}
        @this.pending_count.should == 2
      end
    end
    
    describe "connection pool" do
      before(:each) do
        @beat_count = 0
        @this = Database.connect 'crunch_test', min_connections: 2, heartbeat: 0.01, on_heartbeat: ->{@beat_count += 1}
        EM.set_quantum 10   # So we don't wait forever on our heartbeat calls
      end
      
      it "loads the minimum at startup" do
        @this.connection_count.should == 2
      end
      
      it "stays at min_connections if the number of requests is < connection_count" do
        tick {@this << request}
        sleep 0.05
        @this.connection_count.should == 2
      end
      
      it "stays at min_connections if the number of requests == connection_count" do
        tick {@this << request << request}
        sleep 0.05
        @this.connection_count.should == 2
      end
      
      it "adds more connections if the number of requests > connection_count" do
        tick {3.times {@this << request}}
        sleep 0.05
        @this.connection_count.should == 3
      end
      
      it "adds new connections gradually" do
        tick {8.times {@this << request}}
        sleep 0.02
        @this.connection_count.should be_within(2).of(3)
        sleep 0.1
        @this.connection_count.should == 8
      end
      
      it "removes connections slowly" do
        tick {5.times {@this << request}}
        sleep 0.05
        @this.connection_count.should == 5
        5.times {@this.requests.pop {true}}
        sleep 0.1
        @this.connection_count.should == 5
        sleep 0.2
        @this.connection_count.should == 4
        sleep 0.5
        @this.connection_count.should == 2
      end
        
      it "can add other events to the heartbeat" do
        foo = false
        @this.on_heartbeat = ->{foo = true}
        sleep 0.02
        foo.should == true
      end
        
      it "calls the heartbeat timer" do
        sleep 0.03
        @beat_count.should be_within(1.01).of(2)
      end
      
        
    end
      
    after(:each) do
      # We have to clear the global Databases hash _and_ stop EventMachine to reset to initial state.
      Database.class_variable_set(:@@databases, {})
      if EM.reactor_running?
        EM.run {EM.stop_event_loop}
        Thread.pass while EM.reactor_running?
      end
    end
      
  end
end