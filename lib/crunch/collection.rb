require_relative 'querist'

module Crunch
  
  # Represents a collection within a database.  Cannot be created directly; instead, use the
  # Database#collection method.
  class Collection 
    attr_reader :database, :name, :full_name
        
    # Schedules an object for insertion into the database.  Returns the Document object that
    # is to be inserted.
    #
    # @param [Hash] data The field values to be inserted (_id will be generated if it isn't given)
    # @return [Document] Note: simply having this object doesn't _guarantee_ that it's in the database; it's just reasonable optimism
    def insert(data)
      if data['_id']
        fieldset = Fieldset.new data
      else
        fieldset = Fieldset.new data.merge('_id' => Crunch.oid)
      end
      EventMachine.next_tick do
        message = InsertMessage.new(self, fieldset)
        database << message
      end
      Document.send :new, self, data: fieldset
    end
    
    # Updates multiple records in the collection with the given modifiers. Defaults 'multi'
    # to true, because if you're updating the collection you usually want to update more than
    # one record. If you want to update just one document, call {Document#update} on that object instead.
    # Returns the selector fieldset, in case you want to query on the same documents to verify results.
    #
    # @param [optional, Hash] opts Attribute parameters
    # @option opts [Fieldset, Hash] :selector ({}) Describes the document(s) to be updated (if not given, all documents in the collection will be updated)
    # @option opts [Object] :id If specified, the message's selector will include {'_id' => _val_} (not recommended at the Collection level)
    # @option opts [Fieldset, Hash] :update ({}) The values we're updating -- when given at the Collection level, use a hash of atomic update operators (i.e. '$set' and friends)
    # @option opts [Boolean] :upsert If true, will create a new record if no document matches the selector (a blank selector matches the first document)
    # @option opts [Boolean] :multi (true) If true, updates ALL documents matching the selector rather than the first
    def update(opts={})
      update = {}
      if opts[:id]
        update[:selector] = Fieldset.new (opts[:selector] || {}).merge('_id' => opts[:id])
      else
        update[:selector] = Fieldset.new opts[:selector]
      end
      update[:update] = opts[:update].is_a?(Fieldset) ? opts[:update] : Fieldset.new(opts[:update])
      update[:upsert] = opts[:upsert] if opts.has_key?(:upsert)
      update[:multi] = opts.has_key?(:multi) ? opts[:multi] : true
      message = UpdateMessage.new(self, update)
      EventMachine.next_tick do
        database << message
      end
    end
    
    # Returns a Crunch::Document after it has retrieved itself from the database.
    #
    # @param collection<String> The name of the collection to retrieve from
    # @param id_or_query<Object, Hash> Either the document's ID _or_ a hash of query options
    # @return Crunch::Document
    def document(id_or_query)
      if id_or_query.kind_of?(Hash)
        Document.send :new, self, query: id_or_query
      else
        Document.send :new, self, id: id_or_query
      end
    end
    
    private_class_method :new
    
    private
    
    # Takes the database, the name, and any options.
    def initialize(database, name, opts={})
      @database, @name = database, name
      @full_name = "#{database.name}.#{name}"
    end
  end

end