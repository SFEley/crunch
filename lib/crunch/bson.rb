module Crunch
  module BSON
    # Special constants
    MIN = :bson_min
    MAX = :bson_max
  end
end

require 'crunch/bson/numeric'
require 'crunch/bson/string'
require 'crunch/bson/binary'
require 'crunch/bson/object_id'
require 'crunch/bson/javascript'
require 'crunch/bson/timestamp'
require 'crunch/bson/hash'

