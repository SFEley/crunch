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
    def insert(data)
      EventMachine.next_tick do
        message = InsertMessage.new(self, data)
        database << message
      end
    end
     
    
    private
    # Takes the database, the name, and any options.
    def initialize(database, name)
      @database, @name = database, name
      @full_name = "#{database.name}.#{name}"
    end
  end

end