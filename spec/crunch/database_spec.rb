require File.dirname(__FILE__) + '/../spec_helper'


module Crunch
  describe Database do
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
      
    end
      
  end
end