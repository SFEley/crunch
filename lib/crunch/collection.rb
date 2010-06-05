module Crunch
  
  # Represents a collection within a database.  Cannot be created directly; instead, use the
  # Database#collection method.
  class Collection 
    attr_reader :database, :name, :full_name
    
    private_class_method :new
    
    def <<(message)
    end
    
    # Schedules an object for insertion into the database.  Like Mongo itself, there's
    # no useful return value.
    #
    # @param [Hash] data The document to be inserted
    def insert(data)
      document = Document.send(:new, self, data)
      EventMachine.next_tick do
        message = InsertMessage.new(self, data)
        database << message
      end
      document
    end
     
    # Schedules an update to the database.  Passes all options to the update message.
    # 
    # @param [optional, H
    
    private
    # Takes the database, the name, and any options.
    def initialize(database, name)
      @database, @name = database, name
      @full_name = "#{database.name}.#{name}"
    end
  end

end