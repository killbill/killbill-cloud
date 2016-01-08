require 'erb'
require 'kpm'
require 'pathname'
require 'yaml'

def load_yaml(file)
  return {} unless Pathname.new(file).file?
  raw_kpm = File.new(file).read
  parsed_kpm = ERB.new(raw_kpm).result
  YAML.load(parsed_kpm)
end

def load_kpm_yml
  base = load_yaml("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb")
  overlay = load_yaml("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb.overlay")

  merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
  base.merge(overlay, &merger)
end

def expand_env_variables(yml_kpm)
  return yml_kpm if yml_kpm['killbill'].nil?

  yml_kpm['killbill']['plugins'] ||= {}
  yml_kpm['killbill']['plugins']['java'] ||= []
  yml_kpm['killbill']['plugins']['ruby'] ||= []

  plugin_configurations = ENV.select { |key, value| key.to_s.match(/^KILLBILL_PLUGIN_/) }
  plugin_configurations.each do |key, value|
    # key is for example KILLBILL_PLUGIN_STRIPE
    plugin = key.match(/^KILLBILL_PLUGIN_(.*)/).captures.first

    # Do we know about it?
    group_id, artifact_id, packaging, classifier, version, type = ::KPM::PluginsDirectory.lookup(plugin, true, ENV['KILLBILL_VERSION'] || 'LATEST')
    next if group_id.nil?

    # Plugin already present?
    matches = yml_kpm['killbill']['plugins'][type.to_s].select { |p| p['artifact_id'] == artifact_id || p['name'] == artifact_id }
    next unless matches.empty?

    yml_kpm['killbill']['plugins'][type.to_s] << {'name' => plugin, 'group_id' => group_id, 'artifact_id' => artifact_id, 'packaging' => packaging, 'classifier' => classifier, 'version' => version}
  end

  yml_kpm
end

puts expand_env_variables(load_kpm_yml).to_yaml
