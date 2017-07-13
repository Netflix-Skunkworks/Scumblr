# namespace :test do
#   desc "Test lib source"
#   Rake::TestTask.new(:lib) do |t|
#     t.libs << "test"
#     t.pattern = 'custom/test/**/*_test.rb'
#     t.verbose = true
#   end

#   Rake::TestTask.new(:lib_custom) do |t|
#     t.libs << "test"
#     t.pattern = '../custom/test/**/*_test.rb'
#     t.verbose = true
#   end
# end

# lib_task = Rake::Task["test:lib"]
# lib_custom_task = Rake::Task["test:lib_custom"]
# test_task = Rake::Task[:test]
# test_task.enhance { lib_task.invoke }
# test_task.enhance { lib_custom_task.invoke }
