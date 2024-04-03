# frozen_string_literal: true

# For Bundler.with_clean_env
require 'bundler/setup'
require 'yaml'

PACKAGE_NAME = 'kpm'

require './lib/kpm/version'
VERSION = KPM::VERSION

# See https://www.jruby.org/download
JRUBY_VERSION = '9.4.5.0'
# See https://github.com/Homebrew/homebrew-portable-ruby/releases
HOMEBREW_PORTABLE_RUBY_VERSION = '3.1.4'

# Remove unused files to reduce package size
GEMS_PATH = 'packaging/vendor/ruby/*/gems/*/'
REMOVE_FILES = %w[test tests spec README* CHANGE* Change* COPYING* LICENSE* MIT-LICENSE* doc docs examples ext/*/Makefile .gitignore .travis.yml].freeze
REMOVE_EXTENSIONS = %w[*.md *.c *.h *.rl extconf.rb *.java *.class *.so *.o].freeze

NOARCH_TARGET = 'noarch'
LINUX_X86_TARGET = 'x86_64_linux'
OSX_X86_TARGET = 'el_capitan'
OSX_ARM_TARGET = 'arm64_big_sur'

desc 'Package your app'
task package: %w[package:noarch package:linux:x86_64 package:osx:x86_64 package:osx:arm64]

namespace :package do
  desc 'Package KPM (noarch)'
  task noarch: [:bundle_install, "packaging/jruby-dist-#{JRUBY_VERSION}-bin.tar.gz"] do
    create_package(NOARCH_TARGET, 'noarch')
  end

  namespace :linux do
    desc 'Package KPM for Linux x86_64'
    task x86_64: [:bundle_install, "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{LINUX_X86_TARGET}.bottle.tar.gz"] do
      ensure_ruby_version
      create_package(LINUX_X86_TARGET, 'linux-x86_64')
    end
  end

  namespace :osx do
    desc 'Package KPM for OSX x86_64'
    task x86_64: [:bundle_install, "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{OSX_X86_TARGET}.bottle.tar.gz"] do
      ensure_ruby_version
      create_package(OSX_X86_TARGET, 'osx')
    end

    desc 'Package KPM for OSX arm64'
    task arm64: [:bundle_install, "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{OSX_ARM_TARGET}.bottle.tar.gz"] do
      ensure_ruby_version
      create_package(OSX_ARM_TARGET, 'osx-arm64')
    end
  end

  desc 'Install gems to local directory'
  task bundle_install: [:clean] do
    # abort if version packaging does not exist on repository
    abort "KPM #{VERSION} does not exists in the repository." unless gem_exists?

    sh 'rm -rf packaging/tmp'
    sh 'mkdir -p packaging/tmp'
    sh 'cp packaging/Gemfile packaging/tmp/'
    sh "sed -i 's/VERSION/#{VERSION}/g' packaging/tmp/Gemfile"

    sh 'rm -rf packaging/vendor/ruby/2.*/bundler' # if multiple clones of same repo, may load in wrong one

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

file "packaging/jruby-dist-#{JRUBY_VERSION}-bin.tar.gz" do
  download_noarch_runtime
end

file "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{LINUX_X86_TARGET}.bottle.tar.gz" do
  download_portable_runtime(LINUX_X86_TARGET)
end

file "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{OSX_X86_TARGET}.bottle.tar.gz" do
  download_portable_runtime(OSX_X86_TARGET)
end

file "packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{OSX_ARM_TARGET}.bottle.tar.gz" do
  download_portable_runtime(OSX_ARM_TARGET)
end

def create_package(target, package_dir_suffix)
  pom_version = %r{<version>(.*)</version>}.match(File.read("#{__dir__}/../pom.xml"))[1]
  package_dir = "#{PACKAGE_NAME}-#{pom_version}-#{package_dir_suffix}"
  sh "rm -rf #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/ruby"
  if target == NOARCH_TARGET
    sh "tar -xzf packaging/jruby-dist-#{JRUBY_VERSION}-bin.tar.gz -C #{package_dir}/lib/ruby --strip-components 1"
  else
    sh "tar -xzf packaging/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{target}.bottle.tar.gz -C #{package_dir}/lib/ruby --strip-components 2"
  end

  sh "cp packaging/kpm.sh #{package_dir}/kpm"
  sh "chmod +x packaging/kpm.sh #{package_dir}/kpm"

  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  if target == NOARCH_TARGET
    # Need to tweak a few things to make it work with JRuby
    sh "cp #{package_dir}/lib/ruby/bin/jruby #{package_dir}/lib/ruby/bin/ruby"
    sh "mv #{package_dir}/lib/vendor/ruby #{package_dir}/lib/vendor/jruby"
  end

  sh "cp packaging/Gemfile* #{package_dir}/lib/vendor/"
  sh "sed -i 's/VERSION/#{VERSION}/g' #{package_dir}/lib/vendor/Gemfile"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"

  return if ENV['DIR_ONLY']

  sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
  sh "rm -rf #{package_dir}"
end

def download_noarch_runtime
  sh 'mkdir -p packaging && cd packaging && curl -L -O --fail ' \
     "https://repo1.maven.org/maven2/org/jruby/jruby-dist/#{JRUBY_VERSION}/jruby-dist-#{JRUBY_VERSION}-bin.tar.gz"
end

def download_portable_runtime(target)
  sh 'mkdir -p packaging && cd packaging && curl -L -O --fail ' \
     "https://github.com/Homebrew/homebrew-portable-ruby/releases/download/#{HOMEBREW_PORTABLE_RUBY_VERSION}/portable-ruby-#{HOMEBREW_PORTABLE_RUBY_VERSION}.#{target}.bottle.tar.gz"
end

def gem_exists?
  response = `gem specification 'kpm' -r -v #{VERSION} 2>&1`
  return false if response.nil?

  specification = YAML.load(response)
  specification.instance_of?(Gem::Specification)
end

def ensure_ruby_version
  # Note! Must match HOMEBREW_PORTABLE_RUBY_VERSION above
  expected_ruby_version = HOMEBREW_PORTABLE_RUBY_VERSION.split('_')[0]
  abort "You can only 'bundle install' using Ruby #{expected_ruby_version}, because that's what homebrew-portable-ruby uses." if RUBY_VERSION !~ /#{Regexp.quote(expected_ruby_version)}/
end
