require 'zip/zip'

class Zippy

  include Enumerable


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

  def paths
    map
  end


  def [](entry)
    return nil unless include?(entry)
    zipfile.read(entry)
  end

  def []=(entry, contents)
    zipfile.get_output_stream entry do |s|
      if contents.is_a?(String)
        s.write contents
      elsif contents.respond_to?(:read)
        s.write contents.read
      elsif contents.respond_to?(:to_s)
        s.write contents.to_s
      else#Not sure these last two are different
        s.write "#{contents}"
      end
    end
    zipfile.commit if autocommit?
    true
  end


  def delete(*entries)
    entries.each do |entry|
      zipfile.remove(entry)
    end
    zipfile.commit if autocommit?
    entries
  end

  def rename(old_name, new_name)
    zipfile.rename(old_name, new_name)
    zipfile.commit if autocommit?
    old_name
  end


  def close
    write(filename)
    zipfile.close
  end

  def write(filename)
    return false if empty?
    zipfile.commit
    unless filename == self.filename
      FileUtils.cp(self.filename, filename)
    end
    true
  end

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


  def self.create(filename, entries={}, &b)
    z = new(filename, entries, &b)
    z.close
    z
  end

  def self.open(filename)
    raise(ArgumentError, "file \"#{filename}\" does not exist")
    z = new(filename)
    if block_given?
      yield z
      z.close
    end
    z
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
    @autocommit ||= true
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
