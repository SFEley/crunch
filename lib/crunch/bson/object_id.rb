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
      # With a 12-byte binary string or 24-byte hex string, creates a BSON ObjectID
      # from the values embedded in the string.
      def initialize(given=nil)
        if given
          if given.force_encoding(Encoding::BINARY).bytesize == 12  # Assume a binary data string
            @bin = given
            @timestamp = Time.at @bin[0..3].unpack('N').first
            @machine_id = "\x00#{@bin[4..6]}".unpack('N').first
            @process_id = @bin[7..8].unpack('n').first
            @counter = "\x00#{@bin[9..11]}".unpack('N').first
          elsif given =~ /[0-9a-f]{24}/i  # Hex string
            @hex = given
            @timestamp = @hex[0..7].hex
            @machine_id = @hex[8..13].hex
            @process_id = @hex[14..17].hex
            @counter = @hex[18..23].hex
          else
            raise BSONError, "ObjectID import must be a valid binary or hex string; you gave: #{given}"
          end
        else
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
        @machine_id_bin ||= @machine_id ? threebytes(@machine_id) : @@machine_id_bin
      end
      
      def process_id
        process_id_bin.unpack('n').first
      end
      
      def process_id_bin
        @process_id_bin ||= @process_id ? [@process_id].pack('n') : @@process_id_bin
      end
      
      def counter
        @counter_id ||= begin
          c = counter_bin
          (c.getbyte(0) << 16) + (c.getbyte(1) << 8) + c.getbyte(2)
        end
      end
      
      def counter_bin
        @counter_bin ||= @counter ? threebytes(@counter) : @@counter.resume
      end
      
      # Returns the ObjectID as a hex-encoded string
      def hex
        @hex ||= bin.unpack('H*').first
      end
      alias_method :to_s, :hex
      
      # Returns the ObjectID as a binary encoded string
      def bin
        @bin ||= "#{timestamp_bin}#{machine_id_bin}#{process_id_bin}#{counter_bin}"
      end

      private
      # Returns a three-byte binary string from the given number
      def threebytes(num)
        [num].pack('N')[1..3]
      end
    end
  end
end