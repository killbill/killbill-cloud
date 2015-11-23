This Docker image for Kill Bill will install Tomcat7 inside Ubuntu 14.04. The first time the image is run, the actual Kill Bill installation is bootstrapped (the process is deferred to let you customize installation configuration parameters and system properties).

# How to use this image

To build it:

    make

In order to build a specific version use `make -e VERSION=0.x.y`
In order to build the kaui image `make -e TARGET=kaui` or  `make -e TARGET=kaui -e VERSION=0.x.y`


To debug it:

    make run


To cleanup containers and images:

    make clean


To run it:

    make run-container


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
