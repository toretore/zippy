Gem::Specification.new do |s|
  s.name     = "zippy"
  s.version  = "0.1.0"
  s.date     = "2008-07-25"
  s.summary  = "rubyzip for dummies"
  s.email    = "toredarell@gmail.com"
  s.homepage = "http://github.com/toretore/zippy"
  s.description = "Zippy reads and writes zip files"
  #s.has_rdoc = true
  s.author  = "Tore Darell"
  s.files    = ["lib/zippy.rb", "README", "rails/init.rb", "rails/README"]
  #s.rdoc_options = ["--main", "README.txt"]
  #s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.add_dependency("rubyzip", [">= 0.9.1"])
end
