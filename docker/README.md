Docker images for Kill Bill
---------------------------

See also our [Docker Compose recipes](https://github.com/killbill/killbill-cloud/tree/master/docker/compose).

Images
======

* killbill/base: shared base image with Tomcat 7 and KPM inside Ubuntu 14.04
* killbill/latest: empty base Kill Bill image. The first time it is started, the latest version of Kill Bill is downloaded
* killbill/tagged: image with Kill Bill installed (published on [Docker Hub](https://hub.docker.com/r/killbill/killbill/))
* kaui/latest: empty base Kaui image .The first time it is started, the latest version of Kaui is downloaded
* kaui/tagged: image with Kaui installed (published on [Docker Hub](https://hub.docker.com/r/killbill/kaui/))
* killbill/build: official build environment for all published Kill Bill artifacts (useful for developers)


Environment variables
=====================

Shared environment variables:

  - `KILLBILL_JVM_PERM_SIZE` (default `512m`)
  - `KILLBILL_JVM_MAX_PERM_SIZE` (default `1G`)
  - `KILLBILL_JVM_XMS` (default `1G`)
  - `KILLBILL_JVM_XMX` (default `2G`)
  - `KPM_PROPS` (default `--verify-sha1`)
  - `NEXUS_URL` (default `https://oss.sonatype.org`)
  - `NEXUS_REPOSITORY` (default `releases`)

Kill Bill specific environment variables:

  - `KILLBILL_CONFIG_DAO_URL` (default `jdbc:h2:file:/var/lib/killbill/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE`)
  - `KILLBILL_CONFIG_DAO_USER` (default `killbill`)
  - `KILLBILL_CONFIG_DAO_PASSWORD` (default `killbill`)
  - `KILLBILL_CONFIG_OSGI_DAO_URL` (default `$KILLBILL_CONFIG_DAO_URL`)
  - `KILLBILL_CONFIG_OSGI_DAO_USER` (default `$KILLBILL_CONFIG_DAO_USER`)
  - `KILLBILL_CONFIG_OSGI_DAO_PASSWORD` (default `$KILLBILL_CONFIG_OSGI_DAO_PASSWORD`)
  - `KILLBILL_SHIRO_RESOURCE_PATH` (default `classpath:shiro.ini`)
  - `KILLBILL_SERVER_TEST_MODE` (default `true`)
  - `KILLBILL_METRICS_GRAPHITE` (default `false`)
  - `KILLBILL_METRICS_GRAPHITE_HOST` (default `localhost`)
  - `KILLBILL_METRICS_GRAPHITE_PORT` (default `2003`)

Kaui specific environment variables:

  - `KAUI_URL` (default `http://127.0.0.1:8080`)
  - `KAUI_API_KEY` (default `bob`)
  - `KAUI_API_SECRET` (default `lazar`)
  - `KAUI_CONFIG_DAO_URL` (default `jdbc:mysql://localhost:3306/kaui`)
  - `KAUI_CONFIG_DAO_USER` (default `kaui`)
  - `KAUI_CONFIG_DAO_PASSWORD` (default `kaui`)

There is a [bug in sonatype where the sha1 is wrong](https://issues.sonatype.org/browse/OSSRH-13936) so in order to disable sha1 verification you can start your container using: KPM_PROPS="--verify-sha1=false"


Build
=====

To build an image:

    make

In order to build a specific version use `make -e VERSION=0.x.y`.
In order to build the kaui image `make -e TARGET=kaui` or  `make -e TARGET=kaui -e VERSION=0.x.y`.

To debug it:

    make run


To cleanup containers and images:

    make clean


To run it:

    make run-container
