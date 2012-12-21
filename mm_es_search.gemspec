# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mm_es_search/version"

Gem::Specification.new do |s|
  s.name        = "mm_es_search"
  s.version     = MmEsSearch::VERSION
  s.authors     = ["Jonathan Chambers"]
  s.email       = ["j.chambers@gmx.net"]
  s.homepage    = "https://github.com/jmchambers/mm_es_search"
  s.summary     = %q{Tools to build a mongomapper model that stores and executes complex elasticsearch queries.}
  s.description = %q{Provides modules that can form the basis of a mongomapper class implementing a search model.}

  s.rubyforge_project = "mm_es_search"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
