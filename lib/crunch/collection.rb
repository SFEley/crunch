#encoding: UTF-8
module Crunch
  
  # Crunch::Collections map directly to named MongoDB collections, and one is
  # required for every Document and Query. Like the Database object, the
  # Collection object is a singleton -- calling Collection.new will raise
  # an exception, and there is only one instance of a Collection object
  # for any given name. Request it using Database#collection.
  class Collection
    
    attr_reader :database, :name
    
    # Singleton pattern -- make .new private and return an exception if
    # called from outside
    class << self
      alias_method :new_from_database, :new
      
      def new(*args)
        raise CollectionError, "Crunch::Collection is a singleton. Call " +
          "Database.collection instead of Collection.new."
      end
    end
    
    def initialize(database, name)
      @database = database
      @name = name
    end
    
    # The fully qualified name of the collection, i.e. "database.name"
    def collection_name
      @collection_name ||= "#{database.name}.#{name}"
    end
    
    def inspect
      "«#{name}»"
    end
    
    # Given a hash or Fieldset, or array of same, sends them to the 
    # database as an Insert operation.  Returns the '_id' field of the 
    # document to be inserted, or an array of '_id' fields.  Documents
    # without '_id' fields will have BSON::ObjectID values generated.
    #
    # @param [Hash, Fieldset] *docs One or more hashes or fieldsets
    def insert(*docs)
      fieldsets = docs.map do |doc|
        # Add an _id if there isn't one
        doc = doc.merge({'_id' => Crunch.oid}) unless doc['_id'] || doc[:_id]
        Fieldset.new(doc)
      end
      
      database << InsertRequest.new(self, fieldsets)
      
      if fieldsets.count == 1
        fieldsets.first['_id']
      else
        fieldsets.map{|f| f['_id']}
      end
    end
    
  end
end