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
yml_kpm = YAML.load(parsed_kpm)['killbill']

properties = yml_kpm['properties']
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
require 'yaml'

raw_kpm = File.new("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result

File.open("#{ENV['KILLBILL_CONFIG']}/kpm.yml", 'w') do |file|
  file.write(parsed_kpm)
end
EORUBY

    echo >&2 "Starting Kill Bill installation..."
    jruby -S kpm install $KILLBILL_CONFIG/kpm.yml
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