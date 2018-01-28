# Base image with Tomcat and KPM
FROM ubuntu:16.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# Install Kill Bill dependencies and useful tools
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y \
      apt-utils \
      openjdk-8-jdk \
      curl \
      mysql-client \
      tomcat7 \
      libtcnative-1 \
      unzip \
      telnet \
      sudo \
      vim \
      net-tools \
      less && \
    rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND teletype

# Configure default JAVA_HOME path
RUN ln -s java-8-openjdk-amd64 /usr/lib/jvm/default-java

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.26/jruby-bin-1.7.26.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

ENV TOMCAT_HOME=/var/lib/tomcat7 \
    TOMCAT_CONFIG=/etc/tomcat7 \
    KILLBILL_CONFIG=/etc/killbill

# Configure Tomcat
RUN mkdir -p /usr/share/tomcat7/common/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/common/classes && \
    mkdir -p /usr/share/tomcat7/common && chown -R tomcat7:tomcat7 /usr/share/tomcat7/common && \
    mkdir -p /usr/share/tomcat7/server/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/server/classes && \
    mkdir -p /usr/share/tomcat7/server && chown -R tomcat7:tomcat7 /usr/share/tomcat7/server && \
    mkdir -p /usr/share/tomcat7/shared/classes && chown -R tomcat7:tomcat7 /usr/share/tomcat7/shared/classes && \
    mkdir -p /usr/share/tomcat7/shared && chown -R tomcat7:tomcat7 /usr/share/tomcat7/shared && \
    mkdir -p /tmp/tomcat7-tomcat7-tmp && chown -R tomcat7:tomcat7 /tmp/tomcat7-tomcat7-tmp && \
    chmod g+w /etc/tomcat7/catalina.properties && \
    rm -rf $TOMCAT_HOME/webapps/* && \
    mkdir -p $KILLBILL_CONFIG && \
    chown -R tomcat7:tomcat7 $KILLBILL_CONFIG

ENV KILLBILL_HOME /var/lib/killbill
RUN mkdir -p $KILLBILL_HOME && \
    chown -R tomcat7:tomcat7 $KILLBILL_HOME

# Add tomcat into sudo group and reinitialize the password
RUN usermod -aG sudo tomcat7 && \
    echo 'tomcat7:tomcat7' | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers



# Install KPM
RUN gem install kpm -v 0.5.3

ENV NEXUS_URL=https://oss.sonatype.org \
    NEXUS_REPOSITORY=releases \
    KPM_PROPS=--verify-sha1 \
    KILLBILL_JVM_PERM_SIZE=512m \
    KILLBILL_JVM_MAX_PERM_SIZE=1G \
    KILLBILL_JVM_CMS_INITIATING_OCCUPANCY_FRACTION=70 \
    KILLBILL_JVM_XMS=1G \
    KILLBILL_JVM_XMX=2G

COPY ./ROOT.xml $TOMCAT_CONFIG/Catalina/localhost/ROOT.xml
COPY ./server.xml $TOMCAT_CONFIG/server.xml
COPY ./tomcat.sh /etc/init.d/tomcat.sh
RUN chmod +x /etc/init.d/tomcat.sh

COPY ./kpm_generator.rb $KILLBILL_CONFIG/

USER tomcat7
WORKDIR $TOMCAT_HOME

EXPOSE 8080

CMD ["/etc/init.d/tomcat.sh", "run_tomcat"]
