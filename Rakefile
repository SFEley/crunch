require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "crunch"
    gem.summary = %Q{An asynchronous, opinionated MongoDB driver}
    gem.description = %Q{Crunch is an alternative MongoDB driver with an emphasis on high concurrency, atomic update operations, and document integrity. It uses the Rev event library for non-blocking writes and reads. Its API is more limited than the official Mongo Ruby driver, but simpler and more Rubyish.}
    gem.email = "sfeley@gmail.com"
    gem.homepage = "http://github.com/SFEley/crunch"
    gem.authors = ["Stephen Eley"]
    gem.add_dependency "rev", ">= 0.3.2"
    gem.add_dependency "bson_ext", ">= 1.0"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
