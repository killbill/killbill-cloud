#!/bin/bash

# Run both the main playbook and the one enabling structured logging
$KPM_INSTALL_CMD $KILLBILL_CLOUD_ANSIBLE_ROLES/kaui_json_logging.yml

exec /usr/share/tomcat/bin/catalina.sh run
