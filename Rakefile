# encoding: utf-8

require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rake/testtask'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

task default: :gem

def gemspec
  @spec ||= Gem::Specification.load(Dir['*.gemspec'].first)
end

desc "Build #{gemspec.file_name} into the pkg directory"
task :gem do
  FileUtils.mkdir_p 'pkg'
  Gem::Package.build(gemspec)
  FileUtils.mv gemspec.file_name, 'pkg'
end
task build: :gem

desc "Build and install #{gemspec.file_name}"
task install: :gem do
  sh "gem install pkg/#{gemspec.file_name}"
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rdialog #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
