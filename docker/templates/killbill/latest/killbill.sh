#!/bin/bash

set -a

source "/etc/default/tomcat7"

JAVA_HOME="/usr/lib/jvm/default-java"
CATALINA_HOME="/usr/share/tomcat7"
CATALINA_BASE="/var/lib/tomcat7"
JAVA_OPTS="-Djava.awt.headless=true"
CATALINA_PID="/var/run/tomcat7.pid"
CATALINA_TMPDIR="/tmp/tomcat7-tomcat7-tmp"
LANG=""
JSSE_HOME="/usr/lib/jvm/default-java/jre/"

function install {
  if ! [ -e $KILLBILL_CONFIG/killbill.properties ]; then
    echo >&2 "Kill Bill properties file not found - creating now..."
    jruby <<-EORUBY
require 'erb'
require 'yaml'

raw_kpm = File.new("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result
yml_kpm = YAML.load(parsed_kpm)

properties = yml_kpm['killbill']['properties']
File.open("#{ENV['KILLBILL_CONFIG']}/killbill.properties", 'w') do |file|
  properties.each do |key, value|
    file.write("#{key}=#{value}\n")
  end
end
EORUBY
  fi

  if ! [ -e $KILLBILL_CONFIG/kpm.yml ]; then
    echo >&2 "Kill Bill kpm file not found - creating now..."
    jruby <<-EORUBY
require 'erb'
require 'kpm'
require 'yaml'

raw_kpm = File.new("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result

yml_kpm = YAML.load(parsed_kpm)
yml_kpm['killbill']['plugins'] ||= {}
yml_kpm['killbill']['plugins']['java'] ||= []
yml_kpm['killbill']['plugins']['ruby'] ||= []

plugin_configurations = ENV.select { |key, value| key.to_s.match(/^KILLBILL_PLUGIN_/) }
plugin_configurations.each do |key, value|
  # key is for example KILLBILL_PLUGIN_STRIPE
  plugin = key.match(/^KILLBILL_PLUGIN_(.*)/).captures.first

  # Do we know about it?
  group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup(plugin, true)
  next if group_id.nil?

  # Plugin already present?
  matches = yml_kpm['killbill']['plugins'][type.to_s].select { |p| p['artifact_id'] == artifact_id || p['name'] == artifact_id }
  next unless matches.empty?

  yml_kpm['killbill']['plugins'][type.to_s] << {'group_id' => group_id, 'artifact_id' => artifact_id, 'packaging' => packaging, 'classifier' => classifier, 'version' => version}
end
final_kpm = yml_kpm.to_yaml

File.open("#{ENV['KILLBILL_CONFIG']}/kpm.yml", 'w') do |file|
  file.write(final_kpm)
end
EORUBY

    echo >&2 "Starting Kill Bill installation..."
    jruby -S kpm install $KPM_PROPS $KILLBILL_CONFIG/kpm.yml
  fi
}

function run {
  install

  # Load JVM properties
  export CATALINA_OPTS=$(jruby -rerb -ryaml -e 'puts YAML.load(ERB.new(File.new("#{ENV['"'KILLBILL_CONFIG'"']}/kpm.yml.erb").read).result)["killbill"]["jvm"]')

  cd /var/lib/tomcat7 && /usr/share/tomcat7/bin/catalina.sh run
}

function reinstall {
  rm -f $KILLBILL_CONFIG/killbill.properties \
        $KILLBILL_CONFIG/kpm.yml \
        $TOMCAT_HOME/logs/*
  install
}

case "$1" in
  run)
    run
    ;;
  reinstall)
    reinstall
    ;;
  *)
    echo $"Usage: $0 {run|reinstall}"
    exit 1
esac