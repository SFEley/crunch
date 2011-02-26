require 'forwardable'

module Crunch
  # An enumerable collection of Fieldset objects with optimizations for rapid loading.
  # Recordsets are _almost_ immutable -- they can be appended to, but they can't ever be
  # removed from, and any given element can only be set once. This corresponds with the
  # MongoDB pattern of retrieving a subset of relevant records and iteratively calling 
  # the GET_MORE operation to finish the set.
  class Recordset
    extend Forwardable
    include Enumerable
    
    def_delegators :@records, :each, :<=>, :[], :size, :length
    
    # @param [Fixnum, Enumerable] count_or_elements If any sort of Enumerable, converts each element to a Fieldset and constructs the Recordset from them. If a number, indicates how many binary documents to expect in the second parameter.
    # @param [String] bytes A binary stream containing multiple BSON documents, presumably from MongoDB
    def initialize(count_or_elements, bytes=nil)
      @records = []
      
      case count_or_elements
      when Fixnum
        raise RecordsetError, "Expecting a data stream in the second parameter to Recordset.new" unless bytes.respond_to?(:slice!)
        count_or_elements.times do
          this_length = bytes.unpack('V')[0]
          @records << Fieldset.new(bytes.slice!(0,this_length))
        end
        
      when Enumerable
        @records = count_or_elements.collect{|e| Fieldset.new e}
      end
    end
    
    
  end
end