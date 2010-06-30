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
      
    it "is a singleton" do
      db1 = Database.connect 'crunch_test'
      db2 = Database.connect 'crunch_test'
      db1.should equal(db2)
    end
    
    it "can take a symbol name" do
      db1 = Database.connect 'crunch_test'
      db2 = Database.connect :crunch_test
      db1.should equal(db2)
    end      
  
    it "knows the name is a string even if a symbol is given" do
      db = Database.connect :crunch_test
      db.name.should == 'crunch_test'
    end
    
    describe "collections" do
      
      before(:each) do
        pending
        @database = Database.connect :crunch_test
      end
      
      it "can be retrieved" do
        @database.collection('TestCollection').should be_a(Collection)
      end
      
      it "can be listed" do
        @database.collections.should include('TestCollection')
      end
      
    end
    
    describe "connection" do
      before(:each) do
        Database.class_variable_set(:@@databases, Hash.new)  # Clear the cache so we reinitialize
      end
      
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
              

      it "accepts a username" do
        pending
      end

      it "accepts a password" do
        pending
      end

      it "throws an error if it can't make a read connection" do
        pending
      end

      it "tries to authenticate on 'admin' if the option is given" do
        pending
      end

      it "throws an error if it can't authenticate" do
        pending
      end

      it "creates the database if not told otherwise" do
        pending
      end

      it "does not create the database if told not to" do
        pending
      end

      it "returns a Database object when all is well" do
        pending
      end

      it "returns the same object if called later with the same parameters" do
        pending
      end
      
    end
  
    describe "sending data" do
      before(:each) do
        @this = Database.connect 'crunch_test' && tick
      end

      it "requires a Message" do
        ->{@this << nil}.should raise_error(DatabaseError, /must be a Message/)
      end
      
      # it "passes it to the connection" do
      #    Message.any_instance.expects(:deliver).returns("foobar")
      #    tick until @this.connection.is_a?(EventMachine::Connection)
      #    tick do
      #      @this.connection.expects(:send_data).with("foobar")
      #      @this << Message.new
      #    end
      #  end
       
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
      
      # For more detailed testing, see document/retrieval_spec.rb
      it "can return a document" do
        @this.should respond_to(:document)
      end
      
    end

    
    after(:each) do
      tick {nil}
    end

  end
  
end