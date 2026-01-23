#!/usr/bin/ruby
# WANT_JSON

require 'json'
require 'logger'
require 'stringio'
require 'yaml'

data = {}
File.open(ARGV[0]) do |fh|
  data = JSON.parse(fh.read())
end

unless data['kpm_path'].nil?
  ruby_dir = RUBY_PLATFORM == 'java' ? 'jruby' : 'ruby'
  gem_path_parent = "#{data['kpm_path']}/lib/vendor/#{ruby_dir}"
  ruby_version = Dir.entries(gem_path_parent).select { |f| f =~ /\d+/ }.first
  ENV['GEM_PATH']="#{gem_path_parent}/#{ruby_version}"
  Gem.clear_paths
end
require 'kpm'

# Temporary -- https://github.com/killbill/killbill-cloud/issues/91
log = StringIO.new
logger = Logger.new(log)
logger.level = Logger::INFO

kpm_yml = data['kpm_yml'].is_a?(String) ? YAML.load_file(data['kpm_yml']).to_hash : data['kpm_yml'].to_hash
KPM::Installer.new(kpm_yml, logger).install(kpm_yml['force_download'], kpm_yml['verify_sha1'])

result = {
  'changed' => !(log.string =~ /Successful installation/).nil?,
  'msg' => log.string
}

print JSON.dump(result)
