# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-fields-parser"
  gem.description   = "Fluent output filter plugin for parsing key/value fields in records"
  gem.homepage      = "https://github.com/tomas-zemres/fluent-plugin-fields-parser"
  gem.summary       = gem.description
  gem.version       = File.read("VERSION").strip
  gem.authors       = ["Tomas Pokorny"]
  gem.email         = ["tomas.zemres@gmail.com"]
  gem.has_rdoc      = false
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd"
  gem.add_dependency "logfmt"
  gem.add_development_dependency "rake"
end

