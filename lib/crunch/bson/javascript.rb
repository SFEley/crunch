# encoding: BINARY

module Crunch
  module BSON
    
    # Represents Javascript code in BSON. We need a separate type for this 
    # because the BSON spec says so, and because scope blocks can optionally
    # be passed to pre-assign variables. Note that no validation on the Javascript
    # nor the scope are provided. Users can use the `BSON.javascript` method
    # as a convenience.
    class Javascript
      attr_reader :code, :scope
      
      # Returns a new Javascript object representing the code, and maybe the scope
      # passed in. The BSON code returned by the Javascript#to_s method will vary
      # in type based on whether a scope is given. 
      # @param [String] code  A block of Javascript code
      # @param [optional, Hash] scope A mapping of variables to values
      def initialize(code, scope=nil)
        @code, @scope = code, scope
      end
      
      # Returns itself as a BSON-valid binary string.  If the object has a scope,
      # the structure of the string will conform to the `code_w_scope` specification;
      # otherwise it will simply be a string.
      # @see http://bsonspec.org/#/specification
      def to_s
        @string ||= if @scope
          code = BSON.from_string(@code)
          scope = BSON.from_hash(@scope)
          length = code.bytesize + scope.bytesize + 4
          BSON.from_int(length) << code << scope
        else
          BSON.from_string(@code)
        end
      end
      
      # Returns a three-element array with:
      # 1. The binary BSON type identifier: 13 with no scope, or 15 with scope
      # 2. The length of the full BSON binary string
      # 3. The BSON binary string itself
      def element
        @element ||= [@scope ? 15 : 13, to_s.bytesize, to_s]
      end
      
    end
    
    # Converts the given code and scope to a BSON::Javascript object. 
    # Really just a shortcut to Javascript.new for consistency with other
    # one-way BSON converters (`.cstring`, `.binary`, etc.)
    def self.javascript(*args)
      Javascript.new(*args)
    end
  end
end