module Crunch
  
  # Produces an instruction in the MongoDB Wire Protocol to update or 'upsert' a 
  # document in the database.  Always requires a collection and an *update* hash.
  # May also take either an *id* or a *selector* attribute.  (Supplying both will simply 
  # override the selector's '_id' field.)  If neither is supplied, the updates will be 
  # applied either to the first document in the collection or the entire collection, 
  # depending on the *multi* attribute.
  class UpdateMessage < Message
    @opcode = 2001  # OP_UPDATE
    
    attr_reader :collection_name
    attr_accessor :update, :selector, :upsert, :multi
    
    # Requires a collection, and takes a hash of options (any of which can also be
    # set via attributes after initialization).  The only 'required' option is the
    # update document.
    # @param [Collection] collection What we're updating
    # @param [optional, Hash] opts Attribute parameters
    # @option opts [Hash] :update ({}) The values we're updating -- either the complete document or a hash of atomic update operators (i.e. '$set' and friends)
    # @option opts [Hash] :selector ({}) If specified, describes the document(s) to be updated
    # @option opts [Object] :id If specified, the message's selector will include {'_id' => _val_} (overrides any id already in the selector)
    # @option opts [Boolean] :upsert If true, will create a new record if no document matches the selector (a blank selector matches the first document)
    # @option opts [Boolean] :multi If true, updates ALL documents matching the selector rather than the first
    def initialize(collection, opts={})
      @collection_name = collection.full_name
      @update = opts[:update] || {}
      @selector = opts[:selector] || {}
      @selector.merge!('_id' => opts[:id]) if opts[:id]
      @upsert = opts[:upsert]
      @multi = opts[:multi]
    end
    
    # Gets the selector['_id']
    # @return [Object] selector['_id']
    def id
      selector['_id']
    end
    
    # Sets the selector['_id']
    # @return [Object] selector['_id']
    def id=(val)
      selector['_id'] = val
    end
    
    # Forces #upsert into a Boolean.
    # @return [Boolean]
    def upsert?
      !!@upsert
    end

    # Forces #multi into a Boolean.
    # @return [Boolean]
    def multi?
      !!@multi
    end
    
  end
end