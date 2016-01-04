Docker images for Kill Bill
---------------------------

See also our [Docker Compose recipes](https://github.com/killbill/killbill-cloud/tree/master/docker/compose).

Quick start
===========

To start Kill Bill 0.16.0:

```
docker run -ti -p 8080:8080 killbill/killbill:0.16.0
```

Use `docker-machine env <name>` or the environment variable `$DOCKER_HOST` to get the ip address of the container.

Images
======

* killbill/base: shared base image with Tomcat 7 and KPM inside Ubuntu 14.04
* killbill/latest: empty base Kill Bill image. The first time it is started, the latest version of Kill Bill is downloaded
* killbill/tagged: image with Kill Bill installed (published on [Docker Hub](https://hub.docker.com/r/killbill/killbill/))
* kaui/latest: empty base Kaui image. The first time it is started, the latest version of Kaui is downloaded
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

There is a [bug in sonatype where the sha1 is wrong](https://issues.sonatype.org/browse/OSSRH-13936). In order to disable sha1 verification, you can start your container using: `KPM_PROPS="--verify-sha1=false"`.


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
    
    
Local Development
==================

It becomes fairly easy to start Kill Bill locally on your laptop. For example let's start 2 containers, one with a MySQL database and another one with a Kill Bill server version `0.16.0` (adjust it with the version of your choice).

1. Start the mysql container:

  ```
  docker run -tid --name db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mariadb
  ```

2. Configure the database:
  First, modify the database to make sure it is using the `ROW` `binlog_format`:
  ```
  echo "set global binlog_format = 'ROW'" | mysql -h $(docker-machine ip default) -uroot -p
  ```
  And then create the database `killbill_0_16_0` and add the DDLs:

  * Kill Bill [DDL](http://docs.killbill.io/0.16/ddl.sql)
  * Analytics [DDL](https://github.com/killbill/killbill-analytics-plugin/blob/master/src/main/resources/org/killbill/billing/plugin/analytics/ddl.sql)
  * Stripe [DDL](https://github.com/killbill/killbill-stripe-plugin/blob/master/db/ddl.sql)

3. Start the killbill container with the two plugins `analytics` and `stripe`:

  ```
docker run -tid \
           --name killbill_0_16_0 \
           -p 8080:8080 \
           -p 12345:12345 \
           --link db:dbserver \
           -e KILLBILL_CONFIG_DAO_URL=jdbc:mysql://dbserver:3306/killbill_0_16_0 \
           -e KILLBILL_CONFIG_DAO_USER=root \
           -e KILLBILL_CONFIG_DAO_PASSWORD=root \
           -e KILLBILL_CONFIG_OSGI_DAO_URL=jdbc:mysql://dbserver:3306/killbill_0_16_0 \
           -e KILLBILL_CONFIG_OSGI_DAO_USER=root \
           -e KILLBILL_CONFIG_OSGI_DAO_PASSWORD=root \
           -e KILLBILL_PLUGIN_ANALYTICS=1 \
           -e KILLBILL_PLUGIN_STRIPE=1 \
           killbill/killbill:0.16.0
  ```
4. Play time...

  ```
curl -v \
     -X POST \
     -u admin:password \
     -H 'Content-Type: application/json' \
     -H 'X-Killbill-CreatedBy: admin' \
     -d '{"apiKey": "bob", "apiSecret": "lazar"}' \
     "http://$(docker-machine ip default):8080/1.0/kb/tenants"
  ```

5. Install the KAUI image

  * Create a new database for KAUI
  ```
  create database kaui;
  ```
  
  * Add the [DDL](https://raw.githubusercontent.com/killbill/killbill-admin-ui/master/db/ddl.sql) for KAUI
  
  * Add the initial `admin` user in the `KAUI` database: `insert into kaui_allowed_users (kb_username, description, created_at, updated_at) values ('admin', 'super admin', NOW(), NOW());` 
  
  * Start the KAUI container:
  
  ```
  docker run -tid \
             --name kaui_0_7_0 \
             -p 8989:8080 \
             --link db:dbserver \
             --link killbill_0_16_0:killbill \
             -e KAUI_URL=http://killbill:8080 \
             -e KAUI_API_KEY= \
             -e KAUI_API_SECRET= \
             -e KAUI_CONFIG_DAO_URL=jdbc:mysql://dbserver:3306/kaui \
             -e KAUI_CONFIG_DAO_USER=root \
             -e KAUI_CONFIG_DAO_PASSWORD= \
             killbill/kaui:0.7.0
  ```

6. More Play time... with KAUI

  You can conmnect to KAUI using the url : `http://IP:8989/` where `IP=$(docker-machine ip default)`. You will be able to login as a superadmin using account `admin/password`. From there you can follow our tutorials and documentation.
