#encoding: BINARY
require File.dirname(__FILE__) + '/../../spec_helper'
require 'date'

module Crunch
  describe BSON do
    describe "- from_hash method" do
      it "converts simple hashes" do
        this = {'hi' => 'ho'.force_encoding('ASCII'), 'three' => 3}
        BSON.from_hash(this).should == "\e\x00\x00\x00\x02hi\x00\x03\x00\x00\x00ho\x00\x10three\x00\x03\x00\x00\x00\x00"
      end
      
      it "converts empty hashes" do
        BSON.from_hash({}).should == "\x05\x00\x00\x00\x00"
      end
    end
    
    describe "- from_element method" do
      it "returns three values" do
        foo = BSON.from_element("foo")
        foo.should have(3).elements
      end
      
      it "complains about inputs it doesn't understand" do
        o = Object.new
        ->{BSON.from_element(o)}.should raise_error(BSONError, /unknown/)
      end
      
      it "handles floats" do
        BSON.from_element(3.14).should == [1, 8, "\x1F\x85\xEBQ\xB8\x1E\t@"]
      end
      
      it "handles strings" do
        BSON.from_element("Yowza!".force_encoding('ASCII')).should == [2, 11, "\a\x00\x00\x00Yowza!\x00"]
      end
      
      it "handles hashes" do
        BSON.from_element('foo' => 1, 'bar' => 2).should == [3, 23, "\x17\x00\x00\x00\x10foo\x00\x01\x00\x00\x00\x10bar\x00\x02\x00\x00\x00\x00"]
      end
      
      it "handles 32-bit integers" do
        BSON.from_element(23892).should == [16, 4, "T]\x00\x00"]
      end
      
      it "handles 64-bit integers" do
        BSON.from_element(978058152744563660).should == [18, 8, "\xCC\xB3\x03<\xB5\xC2\x92\r"]
      end
      
      it "does not handle larger integers" do
        ->{BSON.from_element(45247506830213931574861552163)}.should raise_error(BSONError, /larger than/)
      end
      
      it "handles arrays" do
        BSON.from_element([1, :foo, 'eleven'.force_encoding('ASCII'), 3.5, nil, false]).should == [4, 55, "7\x00\x00\x00\x100\x00\x01\x00\x00\x00\x0E1\x00\x04\x00\x00\x00foo\x00\x022\x00\a\x00\x00\x00eleven\x00\x013\x00\x00\x00\x00\x00\x00\x00\f@\n4\x00\b5\x00\x00\x00"]
      end
      
      it "can handle binary data" do
        b = BSON.binary("\x1F\x85\xEBQ\xB8\x1E\t@".force_encoding('BINARY'))
        BSON.from_element(b).should == [5, 13, "\x08\x00\x00\x00\x00\x1F\x85\xEBQ\xB8\x1E\t@"]
      end
      
      it "can handle ObjectIDs" do
        o = BSON::ObjectID.new('4d86bfafa092c90755000001')
        BSON.from_element(o).should == [7, 12, "M\x86\xBF\xAF\xA0\x92\xC9\aU\x00\x00\x01"]
      end
      
      it "can handle false" do
        BSON.from_element(false).should == [8, 1, 0.chr]
      end
      
      it "can handle true" do
        BSON.from_element(true).should == [8, 1, 1.chr]
      end
      
      it "can handle times" do
        t = Time.gm(2011, 3, 21, 14, 19, 30, 115147)  # Down to the microsecond level!
        BSON.from_element(t).should == [9, 8, "\xC3\xED\xC8\xD8.\x01\x00\x00"]
      end

      it "can handle dates" do
        d = Date.parse("2011-03-21")
        BSON.from_element(d).should == [9, 8, "\x00\b\xB6\xD5.\x01\x00\x00"]
      end
        
      it "can handle datetimes" do
        dt = DateTime.parse("2011-03-21 14:19:30")
        BSON.from_element(dt).should == [9, 8, "P\xED\xC8\xD8.\x01\x00\x00"]
      end
      
      it "can handle nil" do
        BSON.from_element(nil).should == [10, 0, ""]
      end
      
      it "can handle regexes" do
        r = /^this$/
        BSON.from_element(r).should == [11, 8, "^this$\x00\x00"]
      end
      
      it "can handle regexes with options" do
        r = /^this$/ix
        BSON.from_element(r).should == [11, 10, "^this$\x00ix\x00"]
      end
      
      it "can handle Javascript" do
        j = BSON.javascript "function() { return this; }"
        BSON.from_element(j).should == [13, 32, "\x1C\x00\x00\x00function() { return this; }\x00"]
      end
      
      it "can handle Javascript with scope" do
        j = BSON.javascript "function() { return this; }", this: 5
        BSON.from_element(j).should == [15, 51, "3\x00\x00\x00\x1C\x00\x00\x00function() { return this; }\x00\x0F\x00\x00\x00\x10this\x00\x05\x00\x00\x00\x00"]
      end
      
      it "can handle symbols" do
        BSON.from_element(:bar).should == [14, 8, "\x04\x00\x00\x00bar\x00"]
      end
      
      it "can handle a BSON Timestamp" do
        ts = BSON::Timestamp.new
        BSON.from_element(ts).should == [17, 8, "\x00\x00\x00\x00\x00\x00\x00\x00"]
      end
      
      it "recognizes the MIN value" do
        BSON.from_element(BSON::MIN).should == [255, 0, '']
      end
      
      it "recognizes the MAX value" do
        BSON.from_element(BSON::MAX).should == [127, 0, '']
      end
        
    end
    
    describe "- to_hash method" do
      it "works for the empty hash" do
        BSON.to_hash("\x05\x00\x00\x00\x00").should == {}
      end
      
      it "works for simple hashes" do
        BSON.to_hash("\e\x00\x00\x00\x02hi\x00\x03\x00\x00\x00ho\x00\x10three\x00\x03\x00\x00\x00\x00").should == {'hi' => 'ho', 'three' => 3}
      end
      
      it "validates correct termination" do
        ->{BSON.to_hash("\e\x00\x00\x00\x02hi\x00\x03\x00\x00\x00ho\x00\x10three\x00\x03\x00\x00\x00")}.should raise_error(BSONError, /invalid document/)
      end
      
      it "can handle floats" do
        BSON.to_hash("\x13\x00\x00\x00\x01test\x00\x1F\x85\xEBQ\xB8\x1E\t@\x00").should == {'test' => 3.14}
      end
      
      it "can handle plain ASCII strings" do
        BSON.to_hash("\x15\x00\x00\x00\x02test\x00\x06\x00\x00\x00hello\x00\x00").should == {'test' => 'hello'}
      end
      
      it "can handle Unicode strings" do
        s = "Hêľľó".force_encoding('UTF-8')
        h = BSON.to_hash("\x19\x00\x00\x00\x02test\x00\n\x00\x00\x00H\xC3\xAA\xC4\xBE\xC4\xBE\xC3\xB3\x00\x00")
        h.should == {'test' => s}
        h['test'].encoding.should == Encoding::UTF_8
      end
      
      it "can handle nested hashes" do 
        BSON.to_hash("*\x00\x00\x00\x03test\x00\x1F\x00\x00\x00\x02foo\x00\x04\x00\x00\x00bar\x00\x02zoo\x00\x04\x00\x00\x00zar\x00\x00\x00").should == {'test' => {'zoo' => 'zar', 'foo' => 'bar'}}
      end
      
      it "can handle arrays" do
        BSON.to_hash("9\x00\x00\x00\x04test\x00.\x00\x00\x00\x100\x00\x01\x00\x00\x00\x021\x00\x04\x00\x00\x00two\x00\x012\x00\x00\x00\x00\x00\x00\x00\b@\x0E3\x00\x05\x00\x00\x00four\x00\x00\x00").should == [1, "two", 3.0, :four]
      end
      
      it "can handle binary data" do
        b = "\x18-DT\xFB!\t@"   # [Math::PI].pack('E')
        out = BSON.to_hash("\x1C\x00\x00\x00\x05test\x00\f\x00\x00\x00\x02\b\x00\x00\x00\x18-DT\xFB!\t@\x00")
        out['test'].should be_a(BSON::Binary)
        out['test'].to_s.should == b
      end
      
      it "can handle an ObjectID" do
        out = BSON.to_hash("\x17\x00\x00\x00\atest\x00M\x8A\xB9\xDD\xA2y\x0E\x03\x89\x00\x00\x01\x00")
        out['test'].should be_a(BSON::ObjectID)
        out['test'].hex.should == '4d8ab9dda2790e0389000001'
      end
      
      it "can handle false" do
        BSON.to_hash("\f\x00\x00\x00\btest\x00\x00\x00").should == {'test' => false}
      end
      
      it "can handle true" do
        BSON.to_hash("\f\x00\x00\x00\btest\x00\x01\x00").should == {'test' => true}
      end
      
      it "can handle the time" do
        BSON.to_hash("\x13\x00\x00\x00\ttest\x00\xD77\xE9\xE5.\x01\x00\x00\x00").should == {'test' => Time.at(1300937390)}
      end
      
      it "can handle nil" do
        BSON.to_hash("\v\x00\x00\x00\ntest\x00\x00").should == {'test' => nil}
      end
      
      it "can handle a regex" do
        BSON.to_hash("\x14\x00\x00\x00\vtest\x00h(.*)\x00ix\x00\x00").should == {'test' => /h(.*)/ix}
      end
      
      it "can handle JavaScript without a scope" do
        out = BSON.to_hash("+\x00\x00\x00\x0Dtest\x00\x1C\x00\x00\x00function() { return this; }\x00\x00")
        out['test'].should be_a(BSON::Javascript)
        out['test'].code.should == 'function() { return this; }'
        out['test'].scope.should be_nil
      end
      
      it "can handle JavaScript with a scope" do
        out = BSON.to_hash("<\x00\x00\x00\x0Ftest\x001\x00\x00\x00\e\x00\x00\x00function() { return foo; }\x00\x0E\x00\x00\x00\x10foo\x00\x03\x00\x00\x00\x00\x00")
        out['test'].should be_a(BSON::Javascript)
        out['test'].code.should == 'function() { return foo; }'
        out['test'].scope.should == {'foo' => 3}
      end
      
      it "can handle symbols" do
        BSON.to_hash("\x13\x00\x00\x00\x0Etest\x00\x04\x00\x00\x00foo\x00\x00").should == {'test' => :foo}
      end
      
      it "can handle 32-bit integers" do
        BSON.to_hash("\x0F\x00\x00\x00\x10test\x00\xE5\xF1\v\x00\x00").should == {'test' => 782821}
      end
      
      it "can handle 64-bit integers" do
        BSON.to_hash("\x13\x00\x00\x00\x12test\x00\xACM\xE6\eB\x00\x00\x00\x00").should == {'test' => 283935919532}
      end
      
      it "can handle BSON timestamps" do
        out = BSON.to_hash("\x13\x00\x00\x00\x11test\x00\xAB\xBE\x8AM\x05\x00\x00\x00\x00")
        out['test'].should be_a(BSON::Timestamp)
        out['test'].time.should == Time.at(1300938411)
        out['test'].counter.should == 5
      end
      
      it "can handle MIN" do
        BSON.to_hash("\v\x00\x00\x00\xFFtest\x00\x00").should == {'test' => BSON::MIN}
      end
      
      it "can handle MAX" do
        BSON.to_hash("\v\x00\x00\x00\x7Ftest\x00\x00").should == {'test' => BSON::MAX}
      end
      
      it "can't handle the unknown" do
        ->{BSON.to_hash("\x14\x00\x00\x00\x94test\x00\x05\x00\x00\x00bleh\x00\x00")}.should raise_error(BSONError, /unknown data type/)
      end
        
    end
    
  end
end
