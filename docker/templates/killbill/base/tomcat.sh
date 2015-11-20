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

function setup_kpm_yml {
  if ! [ -e $KILLBILL_CONFIG/kpm.yml ]; then
    echo >&2 "$KILLBILL_CONFIG/kpm.yml file not found - creating now..."
    jruby $KILLBILL_CONFIG/kpm_generator.rb > $KILLBILL_CONFIG/kpm.yml
  fi
}

function create_annotation {
  if [ -f "$KILLBILL_CONFIG/killbill.properties" ]; then
    METRICS_HOST=$(/usr/bin/perl -ne 'print $1 if m/org.killbill.metrics.graphite.host=(.+)/' $KILLBILL_CONFIG/killbill.properties)
    if [ -n "$METRICS_HOST" ]; then
      echo /usr/bin/curl -m 5 -s -XPOST "http://${METRICS_HOST}:8086/write?db=killbill" --data-binary "restarts,host=$(hostname) version=$1" || true
    fi
  fi
}

function run_tomcat {
  create_annotation

  cd /var/lib/tomcat7 && /usr/share/tomcat7/bin/catalina.sh run
}

function cleanup {
  rm -f $KILLBILL_CONFIG/killbill.properties \
        $KILLBILL_CONFIG/kpm.yml \
        $TOMCAT_HOME/logs/*
}

case "$1" in
  run_tomcat)
    run_tomcat
    ;;
  cleanup)
    cleanup
    ;;
esac
