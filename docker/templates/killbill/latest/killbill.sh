#!/bin/bash

set -e

echo "Installing plugins..."

# Run both the main playbook and the one enabling structured logging
$KPM_INSTALL_CMD $KILLBILL_CLOUD_ANSIBLE_ROLES/killbill_json_logging.yml

until mysql --protocol=TCP -h127.0.0.1 -P3306 -uroot -pkillbill -e "SELECT 1"; do
  echo "Waiting for DB..."
  sleep 5
done

INSTALL_PLUGINS_CMD="$INSTALL_PLUGINS_CMD \
  -e db_config_address=127.0.0.1 \
  -e db_config_port=3306 \
  -e db_config_username=$KILLBILL_DAO_USER \
  -e db_config_password=$KILLBILL_DAO_PASSWORD \
  -e db_config_killbill_db_name=killbill"

eval "$INSTALL_PLUGINS_CMD"

originalfile=$KILLBILL_INSTALL_DIR/config/shiro.ini.template
cat $originalfile | envsubst '${KB_ADMIN_PASSWORD}' > $KILLBILL_INSTALL_DIR/config/shiro.ini

exec /usr/share/tomcat/bin/catalina.sh run
