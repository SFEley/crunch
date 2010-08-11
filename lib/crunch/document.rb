require 'thread'

module Crunch
  
  # Represents a single document object in MongoDB. The data itself is immutable, but may be replaced with a 
  # fresh fieldset by calling the #refresh or #modify methods.
  class Document
    
    attr_reader :collection, :conditions, :options
    
    private_class_method :new
    
    # A shortcut to the '_id' value of the Mongo document. 
    def id
      @data['_id']
    end
        
    # Retrieves the given field value from the fieldset.
    def [](key)
      data[key]
    end
    
    # Serializes the document to a MongoDB binary string.
    def to_bson
      data.to_bson
    end
    
    # The fieldset representing the document's data. If the data has not yet been retrieved and processed
    # from MongoDB, the {#synchronous_fetch} setting determines behavior.
    def data
      @doc_mutex.synchronize do
        if @data.nil?
          if synchronous_fetch?
            @doc_wait.wait(@doc_mutex)
          else
            raise FetchError, "#{self} has not finished loading data!"
          end
        end
        @data
      end
    end

    # The document is ready when it has a fieldset in place. Refreshing the document will cause it to
    # become unready again, so it's a good idea to check this status before referencing data if you're
    # uncertain whether a query's returned yet in asynchronous mode.
    def ready?
      @doc_mutex.synchronize do
        !@data.nil?
      end
    end
    
    # Adds the provided block as a callback on document retrieval, to be executed _after_ the
    # data has been fully loaded. The block may take 0, 1, or 2 parameters, depending on how
    # much manipulation you want to perform in your callback.
    # @yieldparam [optional, Crunch::Document] doc The Document object itself
    # @yieldparam [optional, Crunch::DocumentAgent] agent The deferrable event handler (useful if you want to set further callbacks or raise an error)
    def on_ready(&block)
      case block.arity
      when -1, 0 then retrieve.callback {|*args| retrieve.succeed}  # Pass no parameters up the chain
      when 1 then retrieve.callback {|*args| retrieve.succeed self} # Pass the Document itself up the chain
      when 2 then retrieve.callback {|*args| retrieve.succeed self, retrieve}  # Pass the Document and the DocumentAgent
      else
        raise DocumentError, "Blocks passed to Document#on_ready must take 0, 1, or 2 parameters."
      end
      retrieve.callback &block
    end
      
    # Adds the provided block as a errback on document retrieval, to be executed if the query
    # fails. The block's optional parameter contains an exception created by an error handler
    # up the chain.
    def on_error(&block)
      retrieve.errback &block
    end
    
    # Sets the Document to unready, clears its data, and executes the document query again.
    # This form of the method is asynchronous -- it'll return the Document (or a copy of it
    # with :clone => true) immediately. You can wait for {#ready?} to be true before accessing
    # data, or pass a callback to {#on_ready}. You can also set up a recurring refresh with the
    # :periodic option.
    #
    # @option [Boolean] clone If true, returns a _copy_ of the Document with the refresh scheduled instead of the current Document
    # @option [Numeric, nil, false] periodic If a positive number, sets (or resets) a periodic timer that calls refresh! at the given interval in seconds. Anything else cancels the timer.
    # @yield [doc, agent] Attached as a success handler to the Document or its clone. If a periodic timer is called, the block is called on _every_ success event. (If you're crazy enough to turn on both :periodic and :clone, this is likely the only way to catch the clones that get created.) See the {#onready} method for parameters.
    def refresh!(options={}, &block)
      if options.has_key?(:periodic)
        @periodic.cancel if @periodic   # Just get rid of the old one
        if interval = options.delete(:periodic) and interval.to_f > 0
          @periodic = EventMachine.add_periodic_timer(interval) {self.refresh!(options, &block)}
        end
      else
        @data, @agent = nil, nil
        target = options[:clone] ? self.clone : self
        target.retrieve
        target.on_ready &block if block_given?
        target
      end
    end
    
    # Sets the document to unready, clears its data, and executes the document query again.
    # This form of the method is synchronous -- it will only return when the Document has been
    # completely loaded. The executing thread will sleep until that happens.
    def refresh
      @doc_mutex.synchronize do
        refresh!
        @doc_wait.wait(@doc_mutex)
      end
      self
    end
    
    # If true, accessing the fieldset before it's ready will block the current thread. If false,
    # a {Crunch::FetchError} exception will be raised.  Defaults to true. (Even in asynchronous
    # mode, if you're asking directly for data you _probably_ don't want it to error out.)
    def synchronous_fetch?
      @synchronous_fetch.nil? ? @sychronous_fetch = true : @synchronous_fetch
    end
    alias_method :synchronous_fetch, :synchronous_fetch?
    
    # @see #synchronous_fetch?
    def synchronous_fetch=(val)
      @synchronous_fetch = val
    end
    
    protected

    # Sends the Document's query to the database and sets up a callback to refresh the data
    # once it's ready.
    def retrieve
      @agent ||= DocumentAgent.run(self) do |fieldset| 
        @doc_mutex.synchronize do 
          @data = fieldset
          @doc_wait.broadcast
        end
      end
    end

    # Initializes a document with its values. _Never_ called by application code; it's always initialized by a {Crunch::Group},
    # either implicitly by accessing the Group's collection or by calling {Group.document}.
    #
    # @param [Collection] collection The Collection to which the Document belongs
    # @option [Hash, Fieldset] data Pre-retrieved information with which to populate the document
    # @option [Object] id If provided, and if there was no pre-retrieved data, gets merged into the query's '_id' field to look up the specific document
    def initialize(collection, options={})
      @collection, @options = collection, options
      @doc_mutex = Mutex.new
      @doc_wait = ConditionVariable.new
      @data = Fieldset.new options.delete(:data) if options.has_key?(:data)
      
      # We must have a query
      conditions = options.delete(:conditions) || {}
      if @data && @data['_id']
        conditions['_id'] = @data['_id']
      elsif options[:id]
        conditions['_id'] = options.delete(:id)
      end
      @conditions = Fieldset.new conditions
      
      # Set start and limit to the only sensible values for a single document
      options[:skip] = 0
      options[:limit] = 1
      
      # If we don't have data, start getting some
      retrieve unless @data
      
      if options[:synchronous]
        @doc_mutex.synchronize do
          on_ready{@doc_wait.broadcast}
          @doc_wait.wait(@doc_mutex)
        end
      end
    end
    
  end
end