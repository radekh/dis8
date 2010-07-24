# -*- mode: ruby; -*-
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rd"
  rd.rdoc_files.include('README.rd', 'dis8.rb', 'lib/**/*.rb')
  rd.rdoc_dir = 'doc'
  rd.options << '--all'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end
