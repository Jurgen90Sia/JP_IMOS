require_relative 'test_engine'
directory = File.join(__dir__,'project_core')
Dir.children(directory).select { |name| name.end_with?('_test.rb') }.sort.each do |name|
  require File.join(directory,name)
end
