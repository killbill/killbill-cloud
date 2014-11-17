FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV TOMCAT_HOME /var/lib/tomcat7
ENV TOMCAT_CONFIG /etc/tomcat7

ENV KILLBILL_HOME /var/lib/killbill
ENV KILLBILL_CONFIG /etc/killbill

ENV KILLBILL_GROUP_ID org.kill-bill.billing
ENV KILLBILL_ARTIFACT_ID killbill-profiles-killbill
ENV KILLBILL_VERSION 0.12.0
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

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      curl \
      mysql-client \
      tomcat7 \
      unzip && \
    rm -rf /var/lib/apt/lists/*

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.16/jruby-bin-1.7.16.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

# Install KPM
RUN gem install kpm

# Configure Tomcat
RUN rm -rf $TOMCAT_HOME/webapps/*
COPY ./ROOT.xml $TOMCAT_CONFIG/Catalina/localhost/ROOT.xml

# Configure Kill Bill
RUN mkdir -p $KILLBILL_HOME/bundles $KILLBILL_CONFIG
RUN chown -R tomcat7:tomcat7 $KILLBILL_CONFIG $KILLBILL_HOME
COPY ./ehcache.xml $KILLBILL_CONFIG/ehcache.xml
COPY ./kpm.yml.erb $KILLBILL_CONFIG/kpm.yml.erb
COPY ./logback.xml $KILLBILL_CONFIG/logback.xml
COPY ./killbill.sh /etc/init.d/killbill.sh
RUN chmod +x /etc/init.d/killbill.sh

# Export config and plugins directory
VOLUME $KILLBILL_CONFIG $KILLBILL_HOME

USER tomcat7
WORKDIR $TOMCAT_HOME

EXPOSE 8080

CMD ["/etc/init.d/killbill.sh"]
