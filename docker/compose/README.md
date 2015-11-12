# docker-compose recipes

Note: replace `localhost` with the Docker machine ip (e.g. `$(docker-machine ip dev)`).

To create and start the entire stack, run:

`make`

You can then use `docker-compose`to manage all or individual services (project name is `kb`):

* `docker-compose -p kb ps`
* `docker-compose -p kb restart killbill`
* `docker-compose -p kb restart kaui`

Note that `docker-compose logs` won't work, because all logs are forwarded to [Elasticsearch](http://localhost:5601). The easiest way to find logs for a specific container is to search for the container ID in Kibana.

Individual components can also be run independently (e.g. for debugging). See below.

## Kill Bill

`make run-kb`

Kill Bill is available at [http://localhost:8080](http://localhost:8080) and Kaui at [http://localhost:9090](http://localhost:9090).

A MariaDB container is automatically started, and can be accessed from the Kill Bill container. You need to install the DDL manually the first time:

```
host> docker exec -ti kb_killbill_1 /bin/bash
tomcat7@container:/var/lib/tomcat7$ mysql -h db -uroot -pkillbill -e 'create database killbill; create database kaui'
tomcat7@container:/var/lib/tomcat7$ curl -s http://docs.killbill.io/0.15/ddl.sql | mysql -h db -uroot -pkillbill killbill
tomcat7@container:/var/lib/tomcat7$ curl -s https://raw.githubusercontent.com/killbill/killbill-admin-ui/master/db/ddl.sql | mysql -h db -uroot -pkillbill kaui
```

## Logging

`make run-elk`

Run the latest version of the ELK (Elasticseach, Logstash, Kibana) stack. It will give you the ability to analyze any data set by using the searching/aggregation capabilities of Elasticseach and the visualization power of Kibana.

Logstash listens on 1514 (Syslog protocol). For debugging purposes, the stdout plugin is enabled:

`docker logs -f elk_logstash_1`

The Kibana UI is available at [http://localhost:5601](http://localhost:5601). Port 9200 for Elasticsearch is open for available to the host for Sense.

## Monitoring

`make run-gi`

Run the latest version of InfluxDB and Grafana.

The Grafana UI is available at [http://localhost:3000](http://localhost:3000).
