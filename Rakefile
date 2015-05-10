require 'foodcritic'
require 'rspec/core/rake_task'

# The top of the repository checkout
REPO_TOPDIR = File.dirname(__FILE__)

desc "run food critic on all cookbooks or a single cookbook if passing a cookbook name"
task :foodcritic, :cookbook do |t, args|
  FoodCritic::Rake::LintTask.new do |t|
    t.options = {:cookbook_paths => "#{REPO_TOPDIR}/cookbooks/#{args.cookbook}"}
  end
end

RSpec::Core::RakeTask.new(:unit_test) do |task|
  task.pattern = 'spec/'
  task.rspec_opts = ['--color', '-b']
end

desc "run rspec tests for all cookbooks or a single cookbook if passing a cookbook name"
task :chefspec, :cookbook do |task, args|
  cookbooks_dirs = [File.join(REPO_TOPDIR, "cookbooks", args.cookbook)] if args.cookbook

  (cookbooks_dirs || Dir.glob("#{REPO_TOPDIR}/cookbooks/*")).each do | dir |
    if Dir.exist?(File.join(dir, "spec"))
      puts "Running chefspec tests for #{dir}..."
      Dir.chdir dir
      Rake::Task[:unit_test].execute
    end
  end
end

task :kitchen, :cookbook do |task, args|
  # look to see if cookbook has defined their own custom integration test
  tasks = Rake.application.tasks.select { |task| task.name == "#{args.cookbook}:integration" }
  Dir.chdir(File.join(REPO_TOPDIR, "cookbooks", args.cookbook))

  # run default kitchen task if not
  if tasks.empty?
    system('kitchen test -c --destroy=always') or exit!(1)
  else
    # custom task
    tasks.each do |t|
      puts "Running #{t.name}..."
      t.invoke
    end
  end
end

desc "run validation, foodcritic and chefspec tests"
task :unit_tests => [:foodcritic, :chefspec]

task :default => [:unit_tests]
