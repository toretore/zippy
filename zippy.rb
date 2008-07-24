require 'zip/zip'

class Zippy

  include Enumerable
  #extend Enumerable


  #Make an archive
  #Filename is optional; if none is provided, a generated, temporary
  #filename will be used.
  #If a block is provided, the archive is yielded
  #Takes an optional second parameter which is a hash of entries that will
  #be added after initialization
  def initialize(filename=nil, entries={})
    self.filename = filename if filename
    without_autocommit do
      entries.each{|k,v| self[k] = v }
    end unless entries.empty?
    yield self if block_given?
  end


  def each
    zipfile.each{|e| yield e.name }
  end

  def size
    zipfile.size
  end

  def empty?
    size.zero?
  end

  #Returns the full path to all entries in the archive
  def paths
    map
  end


  #Read an entry
  def [](entry)
    return nil unless include?(entry)
    zipfile.read(entry)
  end

  #Add or change an entry with the name +entry+
  #+contents+ can be a string or an IO
  def []=(entry, contents)
    zipfile.get_output_stream entry do |s|
      if contents.is_a?(String)
        s.write contents
      elsif contents.respond_to?(:read)
        s.write contents.read(1024) until contents.eof?
      elsif contents.respond_to?(:to_s)
        s.write contents.to_s
      else#Not sure these last two are different
        s.write "#{contents}"
      end
    end
    zipfile.commit if autocommit?
    true
  end


  #Delete an entry
  def delete(*entries)
    entries.each do |entry|
      zipfile.remove(entry)
    end
    zipfile.commit if autocommit?
    entries
  end

  #Rename an entry
  def rename(old_name, new_name)
    zipfile.rename(old_name, new_name)
    zipfile.commit if autocommit?
    old_name
  end


  #Close the archive for writing
  def close
    write(filename)
    zipfile.close
  end

  #Write the archive to +filename+
  #If a filename is not provided, it will write
  #to the default filename (self.filename)
  def write(filename)
    return false if empty?
    zipfile.commit
    unless filename == self.filename
      FileUtils.cp(self.filename, filename)
    end
    true
  end

  #Returns the entire archive as a string
  def data
    return nil if empty?
    zipfile.commit
    File.read(filename)
  end


  def filename
    @filename ||= random_filename
  end

  def filename=(filename)
    rename_file(filename)
    @filename = filename
  end


  def zipfile
    @zipfile ||= Zip::ZipFile.new(filename, true)
  end


  #Create a new archive with the name +filename+, populate it
  #and then close it
  #
  #Warning: Will overwrite existing file
  def self.create(filename, entries={}, &b)
    File.unlink(filename) if File.exists?(filename)
    z = new(filename, entries, &b)
    z.close
    z
  end

  #Works the same as new, but require's an explicit filename
  #If a block is provided, it will be closed at the end of the block
  def self.open(filename)
    raise(ArgumentError, "file \"#{filename}\" does not exist") unless File.exists?(filename)
    z = new(filename)
    if block_given?
      yield z
      z.close
    end
    z
  end

  #Iterate each entry name _and_ its contents in the archive +filename+
  def self.each(filename)
    open(filename) do |zip|
      zip.each do |name|
        yield name, zip[name]
      end
    end
  end

  #Returns an array of entry names from the archive +filename+
  #
  #Zippy.list('my.zip') #=> ['foo', 'bar']
  def self.list(filename)
    list = nil
    open(filename){|z| list = z.paths }
    list
  end

  
  #Read the contents of a single entry in +filename+
  def self.read(filename, entry)
    content = nil
    open(filename){|z| content = z[entry] }
    content
  end


private

  def random_filename
    File.join(Dir.tmpdir, "zippy_#{Time.now.to_f.to_s}.zip")
  end


  def rename_file(new_name)
    if @filename && @zipfile && File.exists?(@filename)
      zipfile.close
      File.rename(@filename, new_name)
    end
    @zipfile = nil #Force reload
  end


  def autocommit?
    @autocommit.nil? ? true : @autocommit
  end

  def autocommit=(b)
    @autocommit = !!b
  end

  def without_autocommit
    ac = autocommit?
    self.autocommit = false
    yield
    self.autocommit = ac
  end


end
