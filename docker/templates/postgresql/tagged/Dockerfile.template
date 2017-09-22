FROM postgres
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# VERSION will be expanded in Makefile
ENV KILLBILL_VERSION __VERSION__

RUN echo 'CREATE DATABASE killbill;' > /docker-entrypoint-initdb.d/010_killbill.sql
# New lines are important
RUN printf '\connect killbill;\n\n' >> /docker-entrypoint-initdb.d/010_killbill.sql

RUN echo 'CREATE DATABASE kaui;' > /docker-entrypoint-initdb.d/020_kaui.sql
# New lines are important
RUN printf '\connect kaui;\n\n' >> /docker-entrypoint-initdb.d/020_kaui.sql

RUN set -x \
        && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
        # Install the Kill Bill PostgreSQL DDL bridge
        && wget https://raw.githubusercontent.com/killbill/killbill/killbill-$KILLBILL_VERSION.0/util/src/main/resources/org/killbill/billing/util/ddl-postgresql.sql -O - > /var/tmp/postgres-bridge.sql \
        && cat /var/tmp/postgres-bridge.sql >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && cat /var/tmp/postgres-bridge.sql >> /docker-entrypoint-initdb.d/020_kaui.sql \
        # Install the Kill Bill DDL
        && wget http://docs.killbill.io/$KILLBILL_VERSION/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        # Install the Kaui DDL (point to latest, rarely changes)
        && wget https://raw.githubusercontent.com/killbill/killbill-admin-ui/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/020_kaui.sql \
        # Install the DDL of the most popular plugins (point to latest, rarely changes)
        && wget https://raw.githubusercontent.com/killbill/killbill-stripe-plugin/master/db/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && wget https://raw.githubusercontent.com/killbill/killbill-analytics-plugin/master/src/main/resources/org/killbill/billing/plugin/analytics/ddl.sql -O - >> /docker-entrypoint-initdb.d/010_killbill.sql \
        && apt-get purge -y --auto-remove ca-certificates wget

RUN echo "INSERT INTO kaui_allowed_users (kb_username, description, created_at, updated_at) values ('admin', 'super admin', NOW(), NOW());" >> /docker-entrypoint-initdb.d/020_kaui.sql
