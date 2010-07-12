# Consolidates the attributes and methods shared by classes that are able to make MongoDB queries and 
# receive document data from the server. (I.e., {Crunch::Document} and {Crunch::Group}.)  This places
# a few expectations on the class:
#
# * The class must set or pass any query-relevant options up through its initializer;
# * The class must define a #receive_data method that accepts the Mongo document data (as a Fieldset) and does something with it. (Replaces its own data in the case of a Document, or creates a new Document in its collection for a Group.)
module Crunch
  module Querist
    attr_reader :database, :collection, :query, :fields, :limit, :skip

    def initialize(collection, options)
      @collection = collection
      @database = @collection.database
    
      @query = options[:query]
      @fields = options[:fields]
      @limit = options[:limit]
      @skip = options[:skip]
    
      # Initialize the object with any data if it exists. (This should only matter for Documents, not Groups.)
      if options[:data]
        super(options[:data])
      else
        super()
      end
    end
  
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      @collection.full_name
    end
  
    # Reloads (or loads for the first time) the current data. 
    def refresh
      message = QueryMessage.new self, query: query, fields: fields, limit: limit, skip: skip
      EventMachine.next_tick do
        database << message
      end
    end
  end
end  