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
  if ! [ -e $KAUI_CONFIG/kpm.yml ]; then
    echo >&2 "Kill Bill kpm file not found - creating now..."
    jruby <<-EORUBY
require 'erb'
require 'kpm'
require 'yaml'

raw_kpm = File.new("#{ENV['KAUI_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result

yml_kpm = YAML.load(parsed_kpm)
final_kpm = yml_kpm.to_yaml

File.open("#{ENV['KAUI_CONFIG']}/kpm.yml", 'w') do |file|
  file.write(final_kpm)
end
EORUBY

    echo >&2 "Starting KAUI installation..."
    jruby -S kpm install $KPM_PROPS $KAUI_CONFIG/kpm.yml
  fi
}

function run {
  install

  # Load JVM properties
  JVM_OPTS=$(jruby -rerb -ryaml -e 'puts YAML.load(ERB.new(File.new("#{ENV['"'KAUI_CONFIG'"']}/kpm.yml.erb").read).result)["kaui"]["jvm"]')
  KAUI_OPTS=$(jruby -rerb -ryaml -e 'y=YAML.load(ERB.new(File.new("#{ENV['"'KAUI_CONFIG'"']}/kpm.yml.erb").read).result)["kaui"]["properties"]; puts y.inject("") { |result, (k,v) | result = "#{result} -D#{k}=#{v}" }')
  CATALINA_OPTS="$JVM_OPTS $KAUI_OPTS"
  export CATALINA_OPTS

  cd /var/lib/tomcat7 && /usr/share/tomcat7/bin/catalina.sh run
}

function reinstall {
  rm -f $KAUI_CONFIG/kaui.properties \
        $KAUI_CONFIG/kpm.yml \
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