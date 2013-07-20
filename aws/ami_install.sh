#!/usr/bin/env bash

###################################################################################
#                                                                                 #
#                   Copyright 2010-2013 Ning, Inc.                                #
#                                                                                 #
#      Ning licenses this file to you under the Apache License, version 2.0       #
#      (the "License"); you may not use this file except in compliance with the   #
#      License.  You may obtain a copy of the License at:                         #
#                                                                                 #
#          http://www.apache.org/licenses/LICENSE-2.0                             #
#                                                                                 #
#      Unless required by applicable law or agreed to in writing, software        #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT  #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the  #
#      License for the specific language governing permissions and limitations    #
#      under the License.                                                         #
#                                                                                 #
###################################################################################

# Installation root
KILLBILL_INSTALL="/home/ubuntu/killbill_install"

# Log files
LOGFILE="$KILLBILL_INSTALL/ami_install.log"
ERRFILE="$KILLBILL_INSTALL/ami_install.err"

# Kill Bill directories
KILLBILL_CONFIG="$KILLBILL_INSTALL/config"
KILLBILL_BINARIES="$KILLBILL_INSTALL/binaries"

# Kill Bill installation script
KILLBILL_INSTALL_SCRIPT="killbill_install.rb"

# Tell debconf/dpkg-preconfigure not to try to use a real terminal
APTITUDE="sudo DEBIAN_FRONTEND=noninteractive aptitude -y"

function setup_install_directory_structure() {
    echo "Setup directory structure"
    mkdir $KILLBILL_CONFIG
    mkdir $KILLBILL_BINARIES
    cp "/tmp/$KILLBILL_INSTALL_SCRIPT" $KILLBILL_INSTALL    
    echo "Done with directory structure"
}

function update_packages() {
    echo "Starting updating Ubuntu to latest packages"
    t0=`date +'%s'`
    $APTITUDE update
    echo "Done updating packages, performing safe-upgrade"
    $APTITUDE safe-upgrade
    # Make sure to update again. This is to fix errors like:
    # The following packages have unmet dependencies:
    #  ruby1.9.1-dev : Depends: libc6-dev which is a virtual package.
    $APTITUDE update
    t1=`date +'%s'`
    echo "Done updating Ubuntu to latest packages $((t1-t0)) secs"
    echo
}


function install_package() {
    echo "Starting installing package $1"
    t0=`date +'%s'`
    $APTITUDE install $1
    t1=`date +'%s'`    
    echo "Done installing package $1: $((t1-t0)) secs"
    echo
}

function install_tomcat_from_targz() {
    echo "Installing tomcat $1"    
    t0=`date +'%s'`
    version=7.0.42
    wget --no-verbose -O /tmp/apache-tomcat-$version.tar.gz  https://s3.amazonaws.com/kb-binaries/apache-tomcat-$version.tar.gz
    sudo mv /tmp/apache-tomcat-$version.tar.gz /opt
    (cd /opt; sudo tar zxf ./apache-tomcat-$version.tar.gz)
    echo "Done installing tomcat: $((t1-t0)) secs"
    echo
}

function get_killbill_schema() {
    cd /tmp
    wget -O schema.rb http://kill-bill.org/schema
    ruby schema.rb  > schema.sql
    mysql -h killbill.cn5xamjhatzo.us-east-1.rds.amazonaws.com -u killbill -pkillbill < schema.sql
}


mkdir -p $KILLBILL_INSTALL
rm -f $LOGFILE $ERRFILE
touch $LOGFILE $ERRFILE

# Link file descriptor #3 with stdout and #4 with stderr
exec 3>&1 4>&2
# Redirect stdout to $LOGFILE and stderr to $ERRFILE (use two files so they don't stomp on each other)
exec 1>$LOGFILE 2>$ERRFILE

echo -n "Logfile: "
date
echo "-------------------------------------"
echo

setup_install_directory_structure

update_packages

install_package ruby1.9.1
install_package ruby1.9.1-dev
install_package openjdk-7-jdk
install_package mysql-client

install_tomcat_from_targz

# Restore original stdout/stderr and close the unused descriptors
exec 1>&3 2>&4 3>&- 4>&-