# encoding: BINARY
module Crunch
  module BSON
    
    # Represents a BSON "timestamp" type, which MongoDB uses internally and users will
    # most likely never need to worry about. We include it in our implementation for
    # the sake of irrational completionism.
    class Timestamp

      # If given no parameters, returns a "null" Timestamp (which will be filled in by
      # the server.) If given a binary string, parses it into seconds and counter.
      def initialize(str=nil)
        if str
          @string = str
        else
          @time, @counter, @string = Time.at(0), 0, "\x00\x00\x00\x00\x00\x00\x00\x00"
        end
      end
      
      def time
        @time ||= Time.at(BSON.to_int(@string[0..3]))
      end

      def counter
        @counter ||= BSON.to_int(@string[4..7])
      end
      
      def to_s
        @string
      end
      alias_method :bin, :to_s
                
      
    end
  end
end
