FROM killbill/base
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

RUN mkdir -p $KILLBILL_HOME/bundles

ENV KILLBILL_CONFIG_DAO_URL jdbc:h2:file:$KILLBILL_HOME/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_DAO_USER killbill
ENV KILLBILL_CONFIG_DAO_PASSWORD killbill
ENV KILLBILL_CONFIG_OSGI_DAO_URL jdbc:h2:file:$KILLBILL_HOME/killbill;MODE=MYSQL;DB_CLOSE_DELAY=-1;MVCC=true;DB_CLOSE_ON_EXIT=FALSE
ENV KILLBILL_CONFIG_OSGI_DAO_USER killbill
ENV KILLBILL_CONFIG_OSGI_DAO_PASSWORD killbill

ENV KILLBILL_SHIRO_RESOURCE_PATH classpath:shiro.ini

USER root

COPY ./killbill.sh /etc/init.d/killbill.sh
RUN chmod +x /etc/init.d/killbill.sh

USER tomcat7

COPY ./properties_generator.rb $KILLBILL_CONFIG

COPY ./logback.xml $KILLBILL_CONFIG
COPY ./kpm.yml.erb $KILLBILL_CONFIG

CMD ["/etc/init.d/killbill.sh", "run"]
