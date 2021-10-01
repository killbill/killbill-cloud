# Java Properties
export CATALINA_OPTS="$CATALINA_OPTS
                      "

#
# Load legacy properties (backward compatibility)
#
if [ ! -z ${KAUI_CONFIG_DAO_ADAPTER+x} ]; then
  export KAUI_DB_ADAPTER=$KAUI_CONFIG_DAO_ADAPTER
fi
if [ ! -z ${KAUI_CONFIG_DAO_URL+x} ]; then
  export KAUI_DB_URL=$KAUI_CONFIG_DAO_URL
fi
if [ ! -z ${KAUI_CONFIG_DAO_USER+x} ]; then
  export KAUI_DB_USERNAME=$KAUI_CONFIG_DAO_USER
fi
if [ ! -z ${KAUI_CONFIG_DAO_PASSWORD+x} ]; then
  export KAUI_DB_PASSWORD=$KAUI_CONFIG_DAO_PASSWORD
fi
