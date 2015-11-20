#!/bin/bash

source "/etc/init.d/tomcat.sh"

function install {
  setup_kpm_yml

  echo >&2 "Starting Kaui installation..."
  jruby -S kpm install $KPM_PROPS $KILLBILL_CONFIG/kpm.yml
}

function run {
  install

  # Load JVM properties
  JVM_OPTS=$(jruby -ryaml -e 'puts (YAML.load_file("#{ENV['"'KILLBILL_CONFIG'"']}/kpm.yml") || {})["kaui"]["jvm"]')
  KAUI_OPTS=$(jruby -ryaml -e 'y=(YAML.load_file("#{ENV['"'KILLBILL_CONFIG'"']}/kpm.yml") || {})["kaui"]["properties"]; puts y.inject("") { |result, (k,v) | result = "#{result} -D#{k}=#{v}" }')
  export CATALINA_OPTS="$JVM_OPTS $KAUI_OPTS"

  echo >&2 "Starting Kaui: CATALINA_OPTS=$CATALINA_OPTS"
  cd /var/lib/tomcat7 && /usr/share/tomcat7/bin/catalina.sh run
}

case "$1" in
  run)
    run
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo $"Usage: $0 {run|cleanup}"
    exit 1
esac
