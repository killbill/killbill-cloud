# For Bundler.with_clean_env
require 'bundler/setup'

PACKAGE_NAME = 'kpm'

require './lib/kpm/version'
VERSION = KPM::VERSION

# See https://traveling-ruby.s3-us-west-2.amazonaws.com/list.html
TRAVELING_RUBY_VERSION = '20150715-2.2.2'

# Remove unused files to reduce package size
GEMS_PATH = 'packaging/vendor/ruby/*/gems/*/'
REMOVE_FILES = %w(test tests spec README* CHANGE* Change* COPYING* LICENSE* MIT-LICENSE* doc docs examples ext/*/Makefile .gitignore .travis.yml)
REMOVE_EXTENSIONS = %w(*.md *.c *.h *.rl extconf.rb *.java *.class *.so *.o)

desc 'Package your app'
task :package => %w(package:linux:x86 package:linux:x86_64 package:osx)

namespace :package do
  namespace :linux do
    desc 'Package KPM for Linux x86'
    task :x86 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz"] do
      create_package('linux-x86')
    end

    desc 'Package KPM for Linux x86_64'
    task :x86_64 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package('linux-x86_64')
    end
  end

  desc 'Package KPM for OS X'
  task :osx => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
    create_package('osx')
  end

  desc 'Install gems to local directory'
  task :bundle_install do
    # Note! Must match TRAVELING_RUBY_VERSION above
    expected_ruby_version = TRAVELING_RUBY_VERSION.split('-')[-1]
    if RUBY_VERSION !~ /#{Regexp.quote(expected_ruby_version)}/
      abort "You can only 'bundle install' using Ruby #{expected_ruby_version}, because that's what Traveling Ruby uses."
    end
    sh 'rm -rf packaging/tmp'
    sh 'mkdir -p packaging/tmp'
    sh 'cp packaging/Gemfile packaging/tmp/'

    sh "rm -rf packaging/vendor/ruby/#{expected_ruby_version}/bundler" # if multiple clones of same repo, may load in wrong one

    Bundler.with_clean_env do
      sh 'cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development'
    end

    sh 'rm -rf packaging/tmp'
    sh 'rm -rf packaging/vendor/*/*/cache/*'
    sh 'rm -rf packaging/vendor/ruby/*/extensions'

    # Remove unused files to reduce package size
    REMOVE_FILES.each do |path|
      sh "rm -rf #{GEMS_PATH}#{path}"
    end

    # Remove unused file extensions to reduce package size
    REMOVE_EXTENSIONS.each do |extension|
      sh "find packaging/vendor/ruby -name '#{extension}' | xargs rm -f"
    end
  end

  desc 'Clean up created releases'
  task :clean do
    sh "rm -f #{PACKAGE_NAME}*.tar.gz"
    sh 'rm -rf packaging/vendor'
    sh 'rm -rf packaging/*.tar.gz'
  end
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz" do
  download_runtime('linux-x86')
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime('linux-x86_64')
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
  download_runtime('osx')
end

def create_package(target)
  package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/ruby"

  sh "cp packaging/kpm.sh #{package_dir}/kpm"
  sh "chmod +x packaging/kpm.sh #{package_dir}/kpm"

  sh "cp -pR packaging/vendor #{package_dir}/lib/"

  sh "cp packaging/Gemfile* #{package_dir}/lib/vendor/"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"

  if !ENV['DIR_ONLY']
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
    sh "rm -rf #{package_dir}"
  end
end

def download_runtime(target)
  sh 'mkdir -p packaging && cd packaging && curl -L -O --fail ' +
         "https://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end
