#!/bin/bash

$KPM_INSTALL_CMD

exec /usr/share/tomcat/bin/catalina.sh run
