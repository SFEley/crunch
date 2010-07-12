require_relative 'querist'

module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    
    include Querist
    
    
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
      # Make sure the ID is present in the data and query conditions if it exists
      (options[:data] ||= {})['_id'] = options[:id] if options[:id]
      (options[:query] ||= {})['_id'] = options[:data]['_id'] if options[:data] && options[:data]['_id']
      
      # Set start and limit to the only sensible values for a single document
      options[:skip] = 0
      options[:limit] = 1

      # Set up our query and data. This will pass to the Querist module first, which will do most of the work,
      # then pass just the document data (if any) to Fieldset.
      super
    end
  end
end