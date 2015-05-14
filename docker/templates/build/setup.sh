#!/bin/bash

#
# To import the secret key for releases:
#   gpg --allow-secret-key-import --import secret.gpg.key
#   gpg --import public.gpg.key
#   Update default-key in ~/.gnupg/gpg.conf
#

set -a

ORGANIZATION=killbill

cd $KILLBILL_HOME

for i in `curl -s "https://api.github.com/orgs/$ORGANIZATION/repos?per_page=100" | jruby -rjson -e 'JSON.load(STDIN).each { |r| puts r["clone_url"] }'`; do
  d=`echo $i | grep -oE '([a-zA-Z0-9\-]+).git' | sed s/.git//`
  echo "*** [$d] Setup"

  if [ ! -d $d ]; then
    echo "*** [$d] Cloning $i"
    git clone --depth=50 --branch=master $i
  fi

  cd $d

  git pull

  if [ -f pom.xml ]; then
    echo "Maven setup"
    # Force maven to download dependencies and release artifacts
    mvn -U clean install -DskipTests=true -Ptravis
    mvn -U release:clean
    mvn -U clean
  fi

  if [ -f Gemfile ]; then
    echo "Ruby setup"
    jruby -S bundle install

    # Plugins only
    if [ -f Jarfile ]; then
      jruby -S bundle exec jbundle install
      jruby -S bundle exec rake killbill:clean
    fi
  fi

  cd -
done

cd -
