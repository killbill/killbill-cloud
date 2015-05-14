FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV TOMCAT_HOME /var/lib/tomcat7
ENV TOMCAT_CONFIG /etc/tomcat7

ENV KAUI_HOME /var/lib/kaui
ENV KAUI_CONFIG /etc/kaui

ENV KAUI_GROUP_ID org.kill-bill.billing.kaui
ENV KAUI_ARTIFACT_ID kaui-standalone

ENV KAUI_JVM_PERM_SIZE 512m
ENV KAUI_JVM_MAX_PERM_SIZE 1G
ENV KAUI_JVM_XMS 1G
ENV KAUI_JVM_XMX 2G

# Default local and non multi-tenant properties
ENV KAUI_URL http://127.0.0.1:8080
ENV KAUI_API_KEY bob
ENV KAUI_API_SECRET lazar

ENV KAUI_CONFIG_DAO_URL jdbc:h2:file:$KAUI_HOME/kaui;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KAUI_CONFIG_DAO_USER kaui
ENV KAUI_CONFIG_DAO_PASSWORD kaui

ENV KPM_PROPS --verify-sha1=true

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
RUN mkdir -p $KAUI_HOME/bundles $KAUI_CONFIG
RUN chown -R tomcat7:tomcat7 $KAUI_CONFIG $KAUI_HOME
COPY ./kpm.yml.erb $KAUI_CONFIG/kpm.yml.erb
COPY ./logback.xml $KAUI_CONFIG/logback.xml
COPY ./kaui.sh /etc/init.d/kaui.sh
RUN chmod +x /etc/init.d/kaui.sh

# Export config and plugins directory
VOLUME $KAUI_CONFIG $KAUI_HOME

USER tomcat7
WORKDIR $TOMCAT_HOME

EXPOSE 8080

CMD ["/etc/init.d/kaui.sh", "run"]
