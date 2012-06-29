Gem::Specification.new do |s|
  s.name          = "zippy"
  s.version       = "0.2.1"
  s.date          = "2012-03-15"
  s.summary       = "rubyzip for dummies"
  s.email         = "toredarell@gmail.com"
  s.homepage      = "http://github.com/toretore/zippy"
  s.description   = "Zippy reads and writes zip files"
  s.author        = "Tore Darell"
  s.license       = 'MIT'
  s.files         = ["lib/zippy.rb", "README", "LICENSE"]
  s.require_paths = ['lib']
  s.add_dependency("rubyzip", [">= 0.9.1"])
end
