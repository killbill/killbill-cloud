FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KILLBILL_GROUP_ID org.kill-bill.billing
ENV KILLBILL_ARTIFACT_ID killbill-profiles-killbill
ENV KILLBILL_VERSION 0.12.0
ENV KILLBILL_DEFAULT_BUNDLES_VERSION 0.1.1

ENV KILLBILL_JVM_PERM_SIZE 512m
ENV KILLBILL_JVM_MAX_PERM_SIZE 1G
ENV KILLBILL_JVM_XMS 1G
ENV KILLBILL_JVM_XMX 2G

ENV KILLBILL_CONFIG_DAO_URL jdbc:h2:file:/var/lib/killbill/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_DAO_USER killbill
ENV KILLBILL_CONFIG_DAO_PASSWORD killbill
ENV KILLBILL_CONFIG_OSGI_DAO_URL jdbc:h2:file:/var/lib/killbill/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_OSGI_DAO_USER killbill
ENV KILLBILL_CONFIG_OSGI_DAO_PASSWORD killbill

RUN apt-get update
RUN apt-get -y upgrade

# Install Kill Bill dependencies and useful tools
RUN apt-get -y install tomcat7 mysql-client curl unzip

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN curl -O http://jruby.org.s3.amazonaws.com/downloads/1.7.16/jruby-bin-1.7.16.tar.gz
RUN mkdir /var/lib/jruby
RUN tar -z -x --strip-components=1 -C /var/lib/jruby -f /jruby-bin-*.tar.gz
RUN rm -f /jruby-bin-*.tar.gz

# Install KPM
RUN /var/lib/jruby/bin/jruby -S gem install kpm

# Configure Tomcat
RUN rm -rf /var/lib/tomcat7/webapps/*
ADD ./ROOT.xml /etc/tomcat7/Catalina/localhost/ROOT.xml

# Configure Kill Bill
RUN mkdir -p /var/lib/killbill/bundles
RUN chown -R tomcat7:tomcat7 /var/lib/killbill
RUN mkdir -p /etc/killbill
ADD ./ehcache.xml /etc/killbill/ehcache.xml
ADD ./kpm.yml.erb /etc/killbill/kpm.yml.erb
ADD ./logback.xml /etc/killbill/logback.xml
ADD ./killbill.sh /etc/init.d/killbill.sh
RUN chmod +x /etc/init.d/killbill.sh

EXPOSE 8080

CMD ["/etc/init.d/killbill.sh"]
