require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/git_crecord/**/*test.rb']
end

desc 'run system tests'
task :systemtest do
  sh(File.join(__dir__, 'test/system-test.sh'))
end