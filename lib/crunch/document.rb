require_relative 'querist'

module Crunch
  
  # Represents a single document object in MongoDB. The data itself is immutable, but may be replaced with a 
  # fresh fieldset by calling the #refresh or #modify methods.
  class Document
    
    include Querist
    
    
    private_class_method :new
    
    # A shortcut to the '_id' value of the Mongo document.
    def id
      @data['_id']
    end
    
    def [](key)
      @data[key]
    end
    
    # The document is ready when it has a fieldset in place. Refreshes will simply continue to serve old data
    # until the new fieldset replaces the old. (I.e., a ready document should never become unready.)
    def ready?
      !!@data
    end
    
    
    private

    # Initializes a document with its values. _Never_ called by application code; it's always initialized by a {Crunch::Group},
    # either implicitly by accessing the Group's collection or by calling {Group.document}.
    #
    # @param [Collection] collection The Collection to which the Document belongs
    # @option [Hash, Fieldset] data Pre-retrieved information with which to populate the document
    # @option [Object] id If provided, is merged into the query's '_id' field to look up the specific document
    def initialize(collection, options={})
      @data = Fieldset.new options.delete(:data) if options.has_key?(:data)
      
      if options[:id]
        options[:query] = Fieldset.new((options[:query] || {}).merge '_id' => options.delete(:id))
      else
        options[:query] = Fieldset.new(options[:query])
      end
      
      # Set start and limit to the only sensible values for a single document
      options[:skip] = 0
      options[:limit] = 1

      # Set up our query and data. This will pass to the Querist module, which will do most of the work.
      super
    end
  end
end