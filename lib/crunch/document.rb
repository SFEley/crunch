module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    attr_reader :database, :collection
    
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      @collection.full_name
    end
    
    private_class_method :new
    
    # A shortcut to the '_id' value of the Mongo document.
    def id
      self['_id']
    end
    
    private

    # Initializes a document with its values. _Never_ called by application code; it's always initialized by a {Crunch::Group},
    # either implicitly by accessing the Group's collection or by calling {Group.document}.
    #
    # @param [Collection] collection The Collection to which the Document belongs
    # @option [Hash, Fieldset] data Pre-retrieved information with which to populate the document
    # @option [Object] id If provided, is merged into the '_id' field of both the data and the query
    def initialize(collection, options={})
      @collection = collection
      @database = @collection.database
      
      # Set up our values
      super(options[:data])
      self.merge!('_id' => options[:id]) if options[:id]
    end
  end
end