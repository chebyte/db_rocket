require 'rubygems'
require 'rake'
require 'fileutils'

include FileUtils

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "db_rocket"
    gem.summary = %Q{make your dump db very easy!}
    gem.description = %Q{Db Rocketa allows make your dump db very easy!}
    gem.email = "maurotorres@gmail.com"
    gem.homepage = "http://github.com/chebyte/db_rocket"
    gem.authors = ["Mauro Torres"]
    gem.bindir = 'bin'
    gem.files = Dir['lib/**/*.rb'] + Dir['vendor/*']
#    gem.add_dependency('taps','>=0.3.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

