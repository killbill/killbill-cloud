#!/usr/bin/env bash

set -e

BUNDLE=${BUNDLE-"bundle exec"}
MVN=${MVN-"mvn"}

if [ 'GNU' != "$(tar --help | grep GNU | head -1 | awk '{print $1}')" ]; then
  echo 'Unable to release: make sure to use GNU tar'
  exit 1
fi

# See TRAVELING_RUBY_VERSION in tasks/package.rake
if [[ "$(ruby --version 2>&1 | tail -1 | awk '{print $2}')" != 2.2.2* ]]; then
  echo 'Ruby version 2.2.2 is required'
  exit 1
fi

VERSION=`grep -E '<version>([0-9]+\.[0-9]+\.[0-9]+)</version>' pom.xml | sed 's/[\t \n]*<version>\(.*\)<\/version>[\t \n]*/\1/'`
if [[ -z "$NO_RELEASE" && "$VERSION" != "$(ruby -r./lib/kpm/version.rb -e "print KPM::VERSION")" ]]; then
  echo 'Unable to release: make sure the versions in pom.xml and VERSION match'
  exit 1
fi

if [[ -z "$NO_RELEASE" ]]; then
  echo 'Pushing the gem to Rubygems'
  $BUNDLE rake release
fi

if [[ -z "$NO_RELEASE" ]]; then
  GOAL=gpg:sign-and-deploy-file
  REPOSITORY_ID=ossrh-releases
  URL=https://oss.sonatype.org/service/local/staging/deploy/maven2/
  REPO_VERSION=$VERSION
else
  GOAL=deploy:deploy-file
  REPOSITORY_ID=sonatype-nexus-snapshots
  URL=https://oss.sonatype.org/content/repositories/snapshots/
  REPO_VERSION="$VERSION-SNAPSHOT"
fi

echo "Pushing artifacts to Maven Central"
$MVN $GOAL \
     -DgroupId=org.kill-bill.billing.installer \
     -DartifactId=kpm \
     -Dversion=$REPO_VERSION \
     -Dpackaging=tar.gz \
     -DrepositoryId=$REPOSITORY_ID \
     -Durl=$URL \
     -Dfile=kpm-$VERSION-linux-x86_64.tar.gz \
     -Dclassifier=linux-x86_64 \
     -Dfiles=kpm-$VERSION-linux-x86.tar.gz,kpm-$VERSION-osx.tar.gz \
     -Dclassifiers=linux-x86,osx \
     -Dtypes=tar.gz,tar.gz \
     -DpomFile=pom.xml
