FROM killbill/killbill
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV TOMCAT_HOME /var/lib/tomcat7
ENV TOMCAT_CONFIG /etc/tomcat7

ENV KILLBILL_HOME /var/lib/killbill
ENV KILLBILL_CONFIG /etc/killbill

ENV KILLBILL_GROUP_ID org.kill-bill.billing
ENV KILLBILL_ARTIFACT_ID killbill-profiles-killbill
ENV KILLBILL_VERSION 0.12.1
ENV KILLBILL_DEFAULT_BUNDLES_VERSION 0.1.1

ENV KILLBILL_JVM_PERM_SIZE 512m
ENV KILLBILL_JVM_MAX_PERM_SIZE 1G
ENV KILLBILL_JVM_XMS 1G
ENV KILLBILL_JVM_XMX 2G

ENV KILLBILL_CONFIG_DAO_URL jdbc:h2:file:$KILLBILL_HOME/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_DAO_USER killbill
ENV KILLBILL_CONFIG_DAO_PASSWORD killbill
ENV KILLBILL_CONFIG_OSGI_DAO_URL jdbc:h2:file:$KILLBILL_HOME/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_OSGI_DAO_USER killbill
ENV KILLBILL_CONFIG_OSGI_DAO_PASSWORD killbill


# Update KPM to latest version
USER root
RUN gem update kpm

# Install Kill Bill
RUN kpm pull_kb_server_war --destination=/var/lib/tomcat7/webapps/ROOT.war  $KILLBILL_VERSION

# Revert to tomcat7 user from base image
USER tomcat7

