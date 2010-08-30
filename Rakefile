require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "mongo_store"
    gem.summary = %Q{Rails caching for MongoDB}
    gem.description = %Q{It's ActiveSupport::Cache::MongoStore -- a MongoDB-based provider for the standard Rails cache mechanism.  With an emphasis on fast writes and a memory-mapped architecture, Mongo is well-suited to caching. This gem aims to give you what the ubiquitous MemCacheStore does, but with Mongo's persistence.  (And without having to put a second RAM devourer in an environment already running Mongo.)}
    gem.email = "sfeley@gmail.com"
    gem.homepage = "http://github.com/SFEley/mongo_store"
    gem.authors = ["Stephen Eley"]
    gem.add_dependency "mongo", ">= 0.18.3"
    gem.add_dependency "activesupport", ">= 2.2"
    gem.add_development_dependency "rspec", ">= 1.3"
    gem.add_development_dependency "mocha", ">= 0.9"
    
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

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongo_store #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
