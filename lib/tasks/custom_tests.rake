# Adding test/parsers directory to rake test.
namespace :test do
  desc "Test custom/tests/* code"
  Rails::TestTask.new(custom: 'test:prepare') do |t|
    t.pattern = 'custom/test/**/*_test.rb'
  end

  desc "Test ../custom/tests/* code"
  Rails::TestTask.new(custom_ext: 'test:prepare') do |t|
    t.pattern = '../custom/test/**/*_test.rb'
  end
end

Rake::Task['test:run'].enhance ["test:custom"]
Rake::Task['test:run'].enhance ["test:custom_ext"]
