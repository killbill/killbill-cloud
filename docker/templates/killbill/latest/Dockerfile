FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV TOMCAT_HOME /var/lib/tomcat7
ENV TOMCAT_CONFIG /etc/tomcat7

ENV NEXUS_URL https://oss.sonatype.org
ENV NEXUS_REPOSITORY releases

ENV KILLBILL_HOME /var/lib/killbill
ENV KILLBILL_CONFIG /etc/killbill

ENV KILLBILL_GROUP_ID org.kill-bill.billing
ENV KILLBILL_ARTIFACT_ID killbill-profiles-killbill
ENV KILLBILL_DEFAULT_BUNDLES_VERSION 0.4

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

ENV KPM_PROPS --verify-sha1

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      curl \
      mysql-client \
      tomcat7 \
      unzip \
      telnet \
      sudo && \
    rm -rf /var/lib/apt/lists/*

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.20/jruby-bin-1.7.20.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

# Install KPM
RUN gem install kpm

# Configure Tomcat
RUN mkdir -p /usr/share/tomcat7/common/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/common/classes
RUN mkdir -p /usr/share/tomcat7/common && chown -R tomcat7:tomcat7 /usr/share/tomcat7/common
RUN mkdir -p /usr/share/tomcat7/server/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/server/classes
RUN mkdir -p /usr/share/tomcat7/server && chown -R tomcat7:tomcat7 /usr/share/tomcat7/server
RUN mkdir -p /usr/share/tomcat7/shared/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/shared/classes
RUN mkdir -p /usr/share/tomcat7/shared && chown -R tomcat7:tomcat7 /usr/share/tomcat7/shared
RUN mkdir -p /tmp/tomcat7-tomcat7-tmp && chown -R tomcat7:tomcat7 /tmp/tomcat7-tomcat7-tmp
RUN chmod g+w /etc/tomcat7/catalina.properties
RUN rm -rf $TOMCAT_HOME/webapps/*
COPY ./ROOT.xml $TOMCAT_CONFIG/Catalina/localhost/ROOT.xml

# Add tomcat into sudo group and reinitialize the password
RUN usermod -aG sudo tomcat7
RUN echo "tomcat7:tomcat7" | chpasswd

# Configure Kill Bill
RUN mkdir -p $KILLBILL_HOME/bundles $KILLBILL_CONFIG
RUN chown -R tomcat7:tomcat7 $KILLBILL_CONFIG $KILLBILL_HOME
COPY ./kpm.yml.erb $KILLBILL_CONFIG/kpm.yml.erb
COPY ./logback.xml $KILLBILL_CONFIG/logback.xml
COPY ./killbill.sh /etc/init.d/killbill.sh
RUN chmod +x /etc/init.d/killbill.sh


# Export config and plugins directory
VOLUME $KILLBILL_CONFIG $KILLBILL_HOME

USER tomcat7
WORKDIR $TOMCAT_HOME

EXPOSE 8080

CMD ["/etc/init.d/killbill.sh", "run"]
