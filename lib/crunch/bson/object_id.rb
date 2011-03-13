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
      
      @@process_id_bin = [Process.pid].pack('n')
      @@machine_id_bin = Digest::MD5.digest(Socket.gethostname + Socket.ip_address_list.join)[0..2]
      
      # With no parameters, creates a BSON ObjectID with the current timestamp.
      # With a 12-byte binary string, creates a BSON ObjectID from the values
      # embedded in the string.
      def initialize(given=nil)
        unless given
          @timestamp = Time.now
        end  
      end
      
      def timestamp
        @timestamp ||= Time.now
      end
      
      def timestamp_bin
        @timestamp_bin ||= [timestamp.to_i].pack('N')
      end
      
      def machine_id
        @machine_id ||= begin
          m = machine_id_bin
          (m.getbyte(0) << 16) + (m.getbyte(1) << 8) + m.getbyte(2)
        end
      end
      
      def machine_id_bin
        @machine_id_bin || @@machine_id_bin
      end
      
      def process_id
        process_id_bin.unpack('n').first
      end
      
      def process_id_bin
        @process_id_bin || @@process_id_bin
      end
      
      def counter
        @counter_id ||= begin
          c = counter_bin
          (c.getbyte(0) << 16) + (c.getbyte(1) << 8) + c.getbyte(2)
        end
      end
      
      def counter_bin
        @counter_bin ||= @@counter.resume
      end
      
      # Returns the ObjectID as a hex-encoded string
      def hex
        binary.unpack('H*')
      end
      alias_method :hex, :to_s
      
      # Returns the ObjectID as a binary encoded string
      def bin
        "#{timestamp_bin}#{machine_id_bin}#{process_id_bin}#{counter_bin}"
      end

    end
  end
end