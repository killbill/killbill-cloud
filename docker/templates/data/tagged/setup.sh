#!/usr/bin/env bash


setup_binlog_format() {

  mkdir /home/tmp
  local tmp="/home/tmp"
  local dest="/etc/mysql/my.cnf"
  local origin="$tmp/my.cnf.origin"
  local out="$tmp/my.cnf";

  mv $dest $origin
  found=0;
  while read -r line; do
    name=$line;
    if test $line = "[mysqld]" 2>/dev/null; then
      found=1;
    fi;
    echo $line >> $out;
    if test $found = 1; then
      echo "binlog_format = ROW" >> $out;
      found=0;
    fi;
  done < $origin

  cp $out $dest
}

apply_schema_and_seed_data() {
  if test -f /data/dbdata.tar; then
     (cd / ; tar -xvf  /data/dbdata.tar);
  fi
}

# Fix my.cnf for binlog_format to be set to ROW
setup_binlog_format

# Apply data archive if exists (should include schema for killbill and kaui along with seed data)
apply_schema_and_seed_data

# Container (final) command
#/bin/true (eventually this is what we want)
/bin/bash