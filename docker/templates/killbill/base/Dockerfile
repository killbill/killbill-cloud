# Base image with Tomcat and KPM
FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      openjdk-7-jdk \
      curl \
      mysql-client \
      tomcat7 \
      libtcnative-1 \
      unzip \
      telnet \
      sudo && \
    rm -rf /var/lib/apt/lists/*

# Configure default JAVA_HOME path
RUN ln -s java-7-openjdk-amd64 /usr/lib/jvm/default-java

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.20/jruby-bin-1.7.20.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

ENV TOMCAT_HOME /var/lib/tomcat7
ENV TOMCAT_CONFIG /etc/tomcat7

ENV KILLBILL_CONFIG /etc/killbill

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

RUN mkdir -p $KILLBILL_CONFIG
RUN chown -R tomcat7:tomcat7 $KILLBILL_CONFIG

ENV KILLBILL_HOME /var/lib/killbill
RUN mkdir -p $KILLBILL_HOME
RUN chown -R tomcat7:tomcat7 $KILLBILL_HOME

# Add tomcat into sudo group and reinitialize the password
RUN usermod -aG sudo tomcat7
RUN echo "tomcat7:tomcat7" | chpasswd

# Install KPM
RUN gem install kpm

ENV NEXUS_URL https://oss.sonatype.org
ENV NEXUS_REPOSITORY releases

ENV KPM_PROPS --verify-sha1

ENV KILLBILL_JVM_PERM_SIZE 512m
ENV KILLBILL_JVM_MAX_PERM_SIZE 1G
ENV KILLBILL_JVM_XMS 1G
ENV KILLBILL_JVM_XMX 2G

COPY ./ROOT.xml $TOMCAT_CONFIG/Catalina/localhost/ROOT.xml
COPY ./server.xml $TOMCAT_CONFIG/server.xml
COPY ./tomcat.sh /etc/init.d/tomcat.sh
RUN chmod +x /etc/init.d/tomcat.sh
COPY ./kpm_generator.rb $KILLBILL_CONFIG

USER tomcat7
WORKDIR $TOMCAT_HOME

EXPOSE 8080

CMD ["/etc/init.d/tomcat.sh", "run_tomcat"]
