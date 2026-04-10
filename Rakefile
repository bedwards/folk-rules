require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
  t.warning = false
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    warn "rspec not installed; skipping"
  end
end

begin
  require "standard/rake"
  task default: %i[test spec standard]
rescue LoadError
  task default: %i[test spec]
end
