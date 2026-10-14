# Java Properties
export CATALINA_OPTS="$CATALINA_OPTS"

# JRuby methods excluded from the JIT (comma-separated; set KAUI_JRUBY_JIT_EXCLUDE='' to disable).
# Rails::Engine#call: once JIT-compiled on JRuby 10, Kaui stops setting the session cookie and
# every new login fails with a 500 (killbill/killbill-admin-ui-standalone#131).
KAUI_JRUBY_JIT_EXCLUDE="${KAUI_JRUBY_JIT_EXCLUDE-Rails::Engine#call}"
if [ -n "$KAUI_JRUBY_JIT_EXCLUDE" ]; then
  export CATALINA_OPTS="$CATALINA_OPTS -Djruby.jit.exclude=$KAUI_JRUBY_JIT_EXCLUDE"
fi

if [  -z ${KAUI_SECRET_KEY_BASE+x} ]; then
  export KAUI_SECRET_KEY_BASE=$(head -c 1024 /dev/urandom | base64 | tr -cd "[:upper:][:digit:]" | head -c 129)
fi

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
