#!/bin/bash

source "/etc/init.d/tomcat.sh"

function install {
  setup_kpm_yml

  if ! [ -e $KILLBILL_CONFIG/killbill.properties ]; then
    echo >&2 "$KILLBILL_CONFIG/killbill.properties file not found - creating now..."
    jruby $KILLBILL_CONFIG/properties_generator.rb > $KILLBILL_CONFIG/killbill.properties
  fi

  echo >&2 "Starting Kill Bill installation..."
  jruby -S kpm install $KPM_PROPS $KILLBILL_CONFIG/kpm.yml
}

function run {
  install

  # Load JVM properties
  export CATALINA_OPTS=$(jruby -ryaml -e 'puts (YAML.load_file("#{ENV['"'KILLBILL_CONFIG'"']}/kpm.yml") || {})["killbill"]["jvm"]')

  echo >&2 "Starting Kill Bill: CATALINA_OPTS=$CATALINA_OPTS"
  run_tomcat
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
