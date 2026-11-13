require_relative 'test_engine'
%w[project_core zones].each do |area|
  directory = File.join(__dir__,area)
  Dir.children(directory).select { |name| name.end_with?('_test.rb') }.sort.each do |name|
    require File.join(directory,name)
  end
end
