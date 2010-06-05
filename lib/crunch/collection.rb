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
    
    # Updates multiple records in the collection with the given modifiers. Defaults 'multi'
    # to true, because if you're updating the collection you usually want to update more than
    # one record. If you want to update just one document, call {Document#update} on that object instead.
    #
    # @param [optional, Hash] opts Attribute parameters
    # @option opts [Hash] :selector ({}) Describes the document(s) to be updated (if not given, all documents in the collection will be updated)
    # @option opts [Object] :id If specified, the message's selector will include {'_id' => _val_} (not recommended at the Collection level)
    # @option opts [Hash] :update ({}) The values we're updating -- when given at the Collection level, use a hash of atomic update operators (i.e. '$set' and friends)
    # @option opts [Boolean] :upsert If true, will create a new record if no document matches the selector (a blank selector matches the first document)
    # @option opts [Boolean] :multi (true) If true, updates ALL documents matching the selector rather than the first
    def update(opts={})
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