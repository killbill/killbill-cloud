FROM mariadb
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# VERSION will be expanded in Makefile
ENV KILLBILL_VERSION __VERSION__

RUN echo "SET GLOBAL binlog_format = 'ROW';" > /docker-entrypoint-initdb.d/000_mysql_config.sql

RUN echo 'CREATE DATABASE IF NOT EXISTS `killbill`;' > /docker-entrypoint-initdb.d/010_killbill.sql
RUN echo 'USE killbill;' >> /docker-entrypoint-initdb.d/010_killbill.sql

RUN echo 'CREATE DATABASE IF NOT EXISTS `kaui`;' > /docker-entrypoint-initdb.d/020_kaui.sql
RUN echo 'USE kaui;' >> /docker-entrypoint-initdb.d/020_kaui.sql

RUN set -x \
        && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
        # Install the Kill Bill DDL
        && wget http://docs.killbill.io/$KILLBILL_VERSION/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        # Install the Kaui DDL (point to latest, rarely changes)
        && wget https://raw.githubusercontent.com/killbill/killbill-admin-ui/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/020_kaui.sql \
        # Install the DDL of the most popular plugins (point to latest, rarely changes)
        && wget https://raw.githubusercontent.com/killbill/killbill-stripe-plugin/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && wget https://raw.githubusercontent.com/killbill/killbill-paypal-express-plugin/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && wget https://raw.githubusercontent.com/killbill/killbill-braintree-blue-plugin/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && wget https://raw.githubusercontent.com/killbill/killbill-analytics-plugin/master/src/main/resources/org/killbill/billing/plugin/analytics/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && wget https://raw.githubusercontent.com/killbill/killbill-adyen-plugin/master/src/main/resources/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && apt-get purge -y --auto-remove ca-certificates wget

RUN echo "INSERT INTO kaui.kaui_allowed_users (kb_username, description, created_at, updated_at) values ('admin', 'super admin', NOW(), NOW());" > /docker-entrypoint-initdb.d/021_kaui_admin.sql
