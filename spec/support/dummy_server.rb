# A stub for the other side of connection testing.  All we do is listen on the 
# hold onto the bytes we get, and then dump that buffer when asked what
# they were. 
#
# IMPORTANT SAFETY TIP, THANKS EGON: The buffer is a _module_ variable. 
# This means that there's only one of it, no matter how many connections
# you make, and if you try to have more than one thing going on a time
# you're going to confuse it.  This approach is too dumb for concurrent
# testing. If you're going to try to speed things up, use a smarter stub.

$DUMMY_PORT = 91919

module DummyServer
  @@buffer = "".force_encoding(Encoding::BINARY)
  @@buffer_mutex = Mutex.new
  
  def receive_data(bytes)
    @@buffer_mutex.synchronize {@@buffer += bytes}
  end
  
  def self.received
    buffer = nil
    @@buffer_mutex.synchronize do
      buffer = @@buffer
      @@buffer = "".force_encoding(Encoding::BINARY)
    end
    buffer
  end
  
  def self.clear
    @@buffer_mutex.synchronize do
      @@buffer = "".force_encoding(Encoding::BINARY)
    end
  end
  
  def self.empty?
    @@buffer_mutex.synchronize do
      @@buffer.empty?
    end
  end
end
