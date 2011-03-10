# encoding: BINARY

require 'socket'
require 'digest/md5'

module Crunch
  module BSON
    
    # Represents a twelve-byte ObjectID as defined in the MongoDB spec.
    # @see http://www.mongodb.org/display/DOCS/Object+IDs
    class ObjectID
      
      # A simple binary string counter.
      @@counter = Fiber.new do
        counter = "\x00\x00\x00"
        counter.force_encoding('BINARY')
        loop do
          Fiber.yield counter
          if counter.getbyte(2) == 255
            if counter.getbyte(1) == 255
                counter.setbyte(0, counter.getbyte(0) + 1)
            end
            counter.setbyte(1, counter.getbyte(1) + 1)
          end
          counter.setbyte(2, counter.getbyte(2) + 1)
        end
      end
      
      # An ID reasonably likely to be unique to this machine. The Mongo docs
      # are surprisingly unspecific on how to achieve this. We do it by
      # concatenating the hostname and all IP addresses known to this 
      # machine, hashing the string with MD5, and then taking the first three bytes.
      # @return String
      def self.machine_id
        @machine_id ||= begin
          md5 = Digest::MD5.new
          md5 << Socket.gethostname
          md5 << Socket.ip_address_list.join
          md5.digest[0..2]
        end
      end
      
      # The process ID of this process, cast into two bytes.
      # @return String
      def self.process_id
        @process_id ||= [Process.pid].pack('n')
      end
      
      # The creation time of the object as a binary string.
      def timestamp
        @timestamp ||= [@created_at.to_i].pack('N')
      end
      
      # A monotonically increasing counter as a three-byte big-endian string.
      def counter
        @counter ||= @@counter.resume
      end
      
      # An incrementing 
      def initialize
        @created_at = Time.now.utc
      end
      
      # Returns the ID as a binary string
      def to_s
        "012345678901"
      end
    end
  end
end