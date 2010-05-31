require File.dirname(__FILE__) + '/../spec_helper'

module Crunch

  # Our highest-level object is NOT the connection; it's the database.  
  # Each database has one write connection and may have multiple read
  # connections at any given time, which will be managed automatically
  # by Crunch, and can accept one authentication (if necessary).  This 
  # dramatically simplifies the API.
  describe Database do
  
    it "must be instantiated with connect()" do
      lambda{d = Database.new}.should raise_error(NoMethodError)
    end
    
    it "starts EventMachine if it isn't already running" do
      if EventMachine.reactor_running?
        EventMachine.next_tick {EventMachine.stop}
        while EventMachine.reactor_running?
          sleep(0.1)
        end
      end
      d = Database.connect 'foo'
      EventMachine.next_tick do
        EventMachine.should be_reactor_running
      end
    end
      
  
    describe "connection" do
      it "requires a name" do
        ->{d = Database.connect}.should raise_error(ArgumentError)
      end

      it "defaults to localhost:27017" do
        EventMachine.expects(:connect).with('localhost',27017)
        tick do
          d = Database.connect 'foo'
        end
      end
      
      it "accepts a given host" do
        EventMachine.expects(:connect).with('example.org',27017)
        tick do
          d = Database.connect 'foo', host: 'example.org'
        end
      end
      

      it "accepts a given port" do
        EventMachine.expects(:connect).with('localhost',71072)
        tick do 
          d = Database.connect 'foo', port: 71072
        end
      end
      
      it "keeps a connection" do
        d = Database.connect 'crunch_test'
      end
        

      it "accepts a username"

      it "accepts a password"

      it "throws an error if it can't make a read connection"

      it "tries to authenticate on 'admin' if the option is given"

      it "throws an error if it can't authenticate"

      it "creates the database if not told otherwise"

      it "does not create the database if told not to"

      it "returns a Database object when all is well"

      it "returns the same object if called later with the same parameters"
    end
  
    describe "sending data" do
      before(:each) do
        @this = Database.connect 'crunch_test' && tick
      end

      it "requires a Message" do
        ->{@this << nil}.should raise_error(DatabaseError, /must be a Message/)
      end
      
      it "passes it to the connection" do
        Message.any_instance.expects(:deliver).returns("foobar")
        tick until @this.connection.is_a?(EventMachine::Connection)
        tick do
          @this.connection.expects(:send_data).with("foobar")
          @this << Message.new
        end
      end
      
      it "returns true" do
        ->{@this << Message.new}.call.should == true
      end
        
    end
    
    describe "operation" do
      before(:each) do
        @this = Database.connect 'crunch_test'
      end
      
      it "has a command collection" do
        @this.command.should be_a(CommandCollection)
      end
      
    end

    
    after(:each) do
      tick {nil}
    end

  end
  
end