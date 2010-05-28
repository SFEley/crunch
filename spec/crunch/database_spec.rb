require File.dirname(__FILE__) + '/../spec_helper'

module Crunch

  # Our highest-level object is NOT the connection; it's the database.  
  # Each database has one write connection and may have multiple read
  # connections at any given time, which will be managed automatically
  # by Crunch, and can accept one authentication (if necessary).  This 
  # dramatically simplifies the API.
  describe Crunch::Database do
    before(:each) do
      EventMachine.stop && sleep(0.1) if EventMachine.reactor_running?
    end
  
    it "must be instantiated with connect()" do
      lambda{d = Database.new}.should raise_error(NoMethodError)
    end
    
    it "starts EventMachine if it isn't already running" do
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
  
    describe "operation" do
      before(:each) do
        @this = Database.connect 'crunch_test'
      end
      
      it "has a command collection" do
        @this.command.should be_a(CommandCollection)
      end
      
    end

    

  end
end