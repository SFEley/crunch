require_relative '../querist'

module Crunch
  class DocumentQuerist < Querist
    attr_reader :owner
    
    # Piggybacks onto the Querist initializer, setting a new callback that returns a 
    # single Fieldset from the returned document data. Note that the query created will
    # _always_ have a limit of 1, regardless of what you pass in. Also note that there's
    # still no concept of an owner here. Whatever creates this querist (probably a 
    # Document object) can set its own callback to receive the Fieldset returned.
    #
    # @param [Collection] collection We need to know where to ask
    # @param[Fieldset] query We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] skip Start at this position in the DB's matching records
    def initialize(collection, query, options={})
      options.merge! limit: 1
      super
      
      # This callback relies on the one from Querist breaking the binary data into
      # a parsed header and document data. Since we're only getting one document back,
      # we don't need to loop through that data; we can just deserialize it once.
      callback do |header, document|
        
        # Break if our limit specifier didn't work.
        fail HeaderError.new "Too many documents! We can only process one, but received #{header[:number_returned]}." if header[:number_returned] > 1
        
        # Pass a Fieldset with the document data back up the chain.
        succeed Fieldset.new document
      end
    end
    
    # A convenience method that allows Documents to create and execute queries in a 
    # single method call.
    # Does the following:
    #   1. Creates a new DocumentQuerist object, extracting the collection, query and
    #      options from the Document object passed;
    #   2. If a block is provided, assigns it to the new querist as a callback;
    #   3. Calls the new querist's {#query} method;
    #   4. Returns the new querist so that other reindeer games can be played.
    #
    # @param [Document] document The calling object
    # @yield [fieldset] Becomes a callback in the querist. Use this to capture the document
    #   returned by the database and assign it to something in the calling object.
    # @yieldparam [Fieldset] fieldset The document returned by the database
    def self.run(document, &callback)
      super document.collection, document.query, document.options, &callback
    end
    
    
  end
end

  