#encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe "An archive" do

  before :each do
    @zip = Zippy.new
  end

  after :each do
    @zip.zipfile.close
    File.unlink(@zip.filename) rescue nil
  end

  it "should be an Enumerable" do
    @zip.is_a?(Enumerable).should be_true
  end

  it "should behave like a Hash" do
    @zip.should respond_to("[]")
    @zip.should respond_to("[]=")
  end

  it "should have a zipfile attribute" do
    @zip.should respond_to('zipfile')
    @zip.zipfile.should be_an_instance_of(Zip::ZipFile)
  end

  it "should yield self on initialize" do
    zip = nil
    zap = Zippy.new{|z| zip = z }
    zip.should == zap
  end

  it "should set entries from string keys in the passed hash on initialize" do
    zip = Zippy.new('foo' => 'bar')
    zip.should include('foo')
  end

  it "should set options from symbol keys in the passed hash on initialize" do
    k = Class.new(Zippy){ attr_accessor :foo }
    zip = k.new(:foo => 'bar')
    zip.foo.should == 'bar'
  end

  it "should not set entries from symbol keys on initialize" do
    k = Class.new(Zippy){ attr_accessor :foo }
    zip = k.new(:foo => 'bar')
    zip.should_not include('bar')
  end

  it "should not set options from string keys on initialize" do
    k = Class.new(Zippy){ attr_accessor :foo }
    zip = k.new('foo' => 'bar')
    zip.foo.should_not == 'bar'
  end

  it "should not try to set non-exising attributes from options" do
    zip = Zippy.new('humbaba' => 'scorpion man')
    zip.should_not respond_to(:humbaba)
  end

end

describe "New archive without explicit filename" do

  before :each do
    @zip = Zippy.new
  end

  after :each do
    @zip.zipfile.close
    File.unlink(@zip.filename) rescue nil
  end

  it "should have a randomly generated filename" do
    @zip.filename.should be_an_instance_of(String)
  end

  it "should have a zipfile using the same filename as the archive object" do
    @zip.zipfile.name.should == @zip.filename
  end

  it "should move the zipfile when the filename is changed" do
    @zip.filename = 'foo.zip'
    @zip.filename.should == 'foo.zip'
    @zip.zipfile.name.should == 'foo.zip'
  end

end


describe "New archive with explicit filename" do

  before :each do
    @filename = 'test.zip'
    @zip = Zippy.new(:filename => @filename)
  end

  after :each do
    @zip.zipfile.close
    File.unlink(@zip.filename) rescue nil
  end

  it "should use the filename supplied on initialize" do
    @zip.filename.should == @filename
  end

  it "should use the supplied filename for the zipfile" do
    @zip.zipfile.name.should == @filename
  end

end

describe "Archive" do

  before :each do
    @zip = Zippy.new
  end

  after :each do
    @zip.zipfile.close
    File.unlink(@zip.filename) rescue nil
  end

  it "should write the entry 'foo' with the contents 'bar' on z['foo'] = 'bar'" do
    @zip['foo'] = 'bar'
    @zip['foo'].should == 'bar'
    foo = nil
    @zip.zipfile.get_input_stream('foo'){|s| foo = s.read }
    foo.should == 'bar'
  end

  it "should read the entry 'foo' on z['foo']" do
    @zip['foo'] = 'bar'
    @zip['foo'].should == 'bar'
  end

  it "should return nil on z['foo'] if an entry with the name 'foo' doesn't exist" do
    @zip['humbaba'].should be_nil
  end

  it "should return true on include?('foo') if an entry with the name 'foo' exists, false otherwise" do
    @zip['foo'] = 'bar'
    @zip.include?('foo').should be_true
    @zip.include?('bar').should be_false
  end

  it "should be able to take an IO object on []=" do
    @zip['foo'] = StringIO.new('bar')
    @zip['foo'].should == 'bar'
  end

  it "should return true after a write" do
    #Ok, this is pretty pointless
    @zip.[]=('foo', 'bar').should be_true
  end

  it "should return an array of filenames with paths included on .paths" do
    @zip['foo'] = 'bar'
    @zip['bar/bara.mp3'] = 'hello'
    ['foo', 'bar/bara.mp3'].each{|n| @zip.paths.should include(n) }
  end

  it "should return the archive data on .data" do
    @zip['foo'] = 'bar'
    @zip.data.should =~ /^PK/ #Zip files start with "PK"
  end

  it "should return nil on .data if it's empty" do
    @zip.data.should be_nil
  end

  it "should write the zip data to a file on .write" do
    @zip['foo'] = 'bar'
    @zip.write('test.zip').should be_true
    File.read('test.zip', :encoding => Encoding::BINARY).should =~ /^PK/
  end

  it "should return false on .write if it's empty" do
    @zip.write('test.zip').should be_false
  end

  it "should remove an entry on .delete" do
    @zip['foo'] = 'bar'
    @zip.should include('foo')
    @zip.delete 'foo'
    @zip.should_not include('foo')
  end

  it "should take several entries to .delete" do
    entries = ['foo', 'bar', 'baz']
    entries.each{|e| @zip[e] = 'humbaba' }
    entries.each{|e| @zip.should include(e) }
    @zip.delete(*entries)
    entries.each{|e| @zip.should_not include(e) }
  end

  it "should move an entry to another name on .rename" do
    @zip['foo'] = 'bar'
    @zip.rename 'foo', 'oof'
    @zip.should_not include('foo')
    @zip.should include('oof')
  end

end


describe "Existing archive" do

  before :each do
    name = File.join(File.dirname(__FILE__), 'example.zip')
    FileUtils.cp(name, name+'.b')
    @zip = Zippy.open(name)
  end

  after :each do
    @zip.close
    File.unlink(@zip.filename) rescue nil
    name = File.join(File.dirname(__FILE__), 'example.zip')
    FileUtils.mv(name+'.b', name)
  end


  it "should be readable" do
    @zip.should include('bounce.jpg')
    @zip['text.txt'].should =~ /HUMBABA/
  end

  it "should be editable" do
    @zip['donkey'] = 'horse'
    @zip.delete('bounce.jpg')
    @zip.close
    @zip = Zippy.open(@zip.filename)
    @zip['donkey'].should == 'horse'
    @zip.should_not include('bounce.jpg')
  end

end


describe "Zippy." do

  before :each do
    @filename = File.join(File.dirname(__FILE__), 'example.zip')
  end

  it "create should yield self, write to the provided filename and close" do
    Zippy.create 'test.zip' do |zip|
      zip['foo'] = 'bar'
    end
    File.read('test.zip', :encoding => Encoding::BINARY).should =~ /^PK/
  end

  it "create should require an explicit filename" do
    lambda{ Zippy.create }.should raise_error(ArgumentError)
  end

  it "open should require an explicit filename" do
    lambda{ Zippy.open }.should raise_error(ArgumentError)
  end

  it "open should raise exception when file does not exist" do
    lambda{ Zippy.open('nonexistingfile') }.should raise_error(ArgumentError)
  end

  it "list should return an array of path names from the archive" do
    list = Zippy.list(@filename)
    ['bounce.jpg', 'text.txt'].each{|n| list.should include(n) }
  end

  it "each should iterate each entry name and its contents" do
    names, contents = [], []
    Zippy.each(@filename){|n,c| names << n; contents << c }
    names.should_not be_empty
    contents.should_not be_empty
  end

  it "read should return the contents of a specific entry in the archive" do
    Zippy.read(@filename, 'text.txt').should =~ /HUMBABA/
  end

end
