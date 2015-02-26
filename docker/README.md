This Docker image for Kill Bill will install Tomcat7 inside Ubuntu 14.04. The first time the image is run, the actual Kill Bill installation is bootstrapped (the process is deferred to let you customize installation configuration parameters and system properties).

# How to use this image

To build it:

    make


To debug it:

    make run


To cleanup containers and images:

    make clean


To run it:

    make run-container


The following environment variables are honored:

  - `KILLBILL_GROUP_ID` (default `org.kill-bill.billing`)
  - `KILLBILL_ARTIFACT_ID` (default `killbill-profiles-killbill`)
  - `KILLBILL_VERSION` (default `0.12.0`)
  - `KILLBILL_DEFAULT_BUNDLES_VERSION` (default `0.1.1`)
  - `KILLBILL_JVM_PERM_SIZE` (default `512m`)
  - `KILLBILL_JVM_MAX_PERM_SIZE` (default `1G`)
  - `KILLBILL_JVM_XMS` (default `1G`)
  - `KILLBILL_JVM_XMX` (default `2G`)
  - `KILLBILL_CONFIG_DAO_URL` (default `jdbc:h2:file:/var/lib/killbill/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE`)
  - `KILLBILL_CONFIG_DAO_USER` (default `killbill`)
  - `KILLBILL_CONFIG_DAO_PASSWORD` (default `killbill`)
  - `KILLBILL_CONFIG_OSGI_DAO_URL` (default `jdbc:h2:file:/var/lib/killbill/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE`)
  - `KILLBILL_CONFIG_OSGI_DAO_USER` (default `killbill`)
  - `KILLBILL_CONFIG_OSGI_DAO_PASSWORD` (default `killbill`)
  - `KPM_PROPS` (default `--verify-sha1=true`)


There is a [bug in sonatype where the sha1 is wrong](https://issues.sonatype.org/browse/OSSRH-13936) so in order to disable sha1 verification you can start your container using: KPM_PROPS="--verify-sha1=false"