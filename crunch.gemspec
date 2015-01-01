# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "crunch/version"

Gem::Specification.new do |s|
  s.name      = %q{crunch}
  s.version   = Crunch::VERSION
  s.platform  = Gem::Platform::RUBY

  s.authors     = ["Stephen Eley"]
  s.email       = ["sfeley@gmail.com"]
  s.homepage    = "http://github.com/SFEley/crunch"
  s.summary     = %q{An asynchronous, opinionated MongoDB driver}
  s.description = %q{Crunch is an alternative MongoDB driver with an emphasis on high concurrency, atomic update operations, and document integrity. It uses the Rev event library for non-blocking writes and reads. Its API is more limited than the official Mongo Ruby driver, but simpler and more Rubyish.}
  s.rubyforge_project = "crunch"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [
    "LICENSE.markdown",
     "README.markdown"
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.add_runtime_dependency      'eventmachine', "~>1.0"
  s.add_development_dependency  'rspec', '~>3.0'
  s.add_development_dependency  'rspec-collection_matchers', '~>1.1'
  s.add_development_dependency  'mocha', '>0.9'
  s.add_development_dependency  'mongo', '~>1.11'
end
