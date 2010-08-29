module Crunch
  class QueryAgent < Agent
    
    # Piggybacks onto the Agent initializer, setting a new callback that returns a 
    # Recordset from the returned document data. Whatever creates this agent (probably a 
    # Query or Collection object) can set its own callback to receive the Recordset returned.
    #
    # @param [Collection] collection We need to know where to ask
    # @param [Fieldset] query We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] limit Only retrieve this many records
    # @option [Integer] skip Start at this position in the DB's matching records
    def initialize(collection, query, options={})
      options[:limit] ||= 0
      super
    end
  end
end