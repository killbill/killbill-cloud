#!/usr/bin/env bash

OUTPUT="/tmp/install.out"

KILLBILL_INSTALL="/home/ubuntu/killbill_install"
KILLBILL_CONFIG="$KILLBILL_INSTALL/config"
KILLBILL_BINARIES="$KILLBILL_INSTALL/binaries"

KILLBILL_INSTALL_SCRIPT="killbill_install.rb"

CATALINA_HOME="/opt/apache-tomcat-7.0.40"

function setup_install_directory_structure() {
    echo "Setup directory structure"
    mkdir $KILLBILL_INSTALL
    mkdir $KILLBILL_CONFIG
    mkdir $KILLBILL_BINARIES
    cp "/tmp/$KILLBILL_INSTALL_SCRIPT" $KILLBILL_INSTALL    
    echo "Done with directory structure"
}

function update_packages() {
    echo "Starting updating Ubuntu to latest packages"
    t0=`date +'%s'`
    sudo aptitude -y update
    echo "Done updating packages, performing safe-upgrade"
    sudo aptitude -y safe-upgrade
    t1=`date +'%s'`    
    echo "Done updating Ubuntu to latest packages $((t1-t0)) secs"
    echo
}


function install_package() {
    echo "Starting installing package $1"
    t0=`date +'%s'`
    sudo aptitude -y install $1 >> $OUTPUT
    t1=`date +'%s'`    
    echo "Done installing package $1: $((t1-t0)) secs"
    echo
}

function install_tomcat_from_targz() {
    echo "Installing tomcat $1"    
    t0=`date +'%s'`
    wget -O /tmp/apache-tomcat-7.0.40.tar.gz  http://mirrors.ibiblio.org/apache/tomcat/tomcat-7/v7.0.40/bin/apache-tomcat-7.0.40.tar.gz
    sudo mv /tmp/apache-tomcat-7.0.40.tar.gz /opt
    (cd /opt; sudo tar zxvf ./apache-tomcat-7.0.40.tar.gz)
    echo "Done installing tomcat: $((t1-t0)) secs"
    echo
}

function get_killbill_schema() {
    cd /tmp
    wget -O schema.rb http://kill-bill.org/schema
    ruby schema.rb  > schema.sql
    mysql -h killbill.cn5xamjhatzo.us-east-1.rds.amazonaws.com -u killbill -pkillbill < schema.sql
}


rm -f $OUTPUT
touch $OUTPUT

setup_install_directory_structure

update_packages

install_package ruby1.9.1
install_package ruby1.9.1-dev
install_package openjdk-7-jdk
install_package mysql-client

install_tomcat_from_targz
