# Shell image that installs Kill Bill on startup
FROM killbill/base
LABEL maintainer="killbilling-users@googlegroups.com"

# The base image has set up a fully functioning Tomcat with default config files.
# Remove them, so they are regenerated on demand based on the environment variables
# (Ansible sets `force: no` by default to avoid clobbering manually customized files).
RUN ["/bin/bash", "-c", "rm -f $CATALINA_BASE/conf/{context.xml,server.xml,web.xml} $CATALINA_BASE/bin/setenv.sh"]

ENV KILLBILL_INSTALL_DIR=/var/lib/killbill

# Default configuration options
ENV KILLBILL_BUNDLE_INSTALL_DIR=$KILLBILL_INSTALL_DIR/bundles
ENV KILLBILL_JRUBY_CONF_DIR=$KILLBILL_INSTALL_DIR/config
ENV KILLBILL_SERVER_BASE_URL=http://$ENV_HOST_IP:8080
ENV KILLBILL_KPM_PATH=$KPM_INSTALL_DIR/kpm-latest/kpm
ENV KILLBILL_KPM_BUNDLES_PATH=$KILLBILL_BUNDLE_INSTALL_DIR

COPY ./killbill.sh $KILLBILL_INSTALL_DIR

ENV KPM_INSTALL_CMD="ansible-playbook $ANSIBLE_OPTS  \
                                      -e kpm_install_dir=$KPM_INSTALL_DIR \
                                      -e kpm_yml=$KILLBILL_INSTALL_DIR/kpm.yml \
                                      -e kb_config_dir=$KILLBILL_INSTALL_DIR \
                                      -e kb_plugins_dir=$KILLBILL_INSTALL_DIR/bundles \
                                      -e tomcat_owner=$TOMCAT_OWNER \
                                      -e tomcat_group=$TOMCAT_GROUP \
                                      -e catalina_base=$CATALINA_BASE \
                                      $KILLBILL_CLOUD_ANSIBLE_ROLES/killbill.yml"

ENV KPM_DIAGNOSTIC_CMD="ansible-playbook $ANSIBLE_OPTS  \
                                         -e kpm_install_dir=$KPM_INSTALL_DIR \
                                         -e kpm_yml=$KILLBILL_INSTALL_DIR/kpm.yml \
                                         -e kb_config_dir=$KILLBILL_INSTALL_DIR \
                                         -e kb_plugins_dir=$KILLBILL_INSTALL_DIR/bundles \
                                         -e tomcat_owner=$TOMCAT_OWNER \
                                         -e tomcat_group=$TOMCAT_GROUP \
                                         -e catalina_base=$CATALINA_BASE \
                                         $KILLBILL_CLOUD_ANSIBLE_ROLES/diagnostic.yml"

ENV MIGRATIONS_CMD="ansible-playbook $ANSIBLE_OPTS \
                                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                                     -e kpm_yml=$KILLBILL_INSTALL_DIR/kpm.yml \
                                     -e kb_config_dir=$KILLBILL_INSTALL_DIR \
                                     -e kb_plugins_dir=$KILLBILL_INSTALL_DIR/bundles \
                                     -e flyway_owner=$TOMCAT_OWNER \
                                     -e flyway_group=$TOMCAT_GROUP \
                                     -e tomcat_owner=$TOMCAT_OWNER \
                                     -e tomcat_group=$TOMCAT_GROUP \
                                     -e catalina_base=$CATALINA_BASE \
                                     $KILLBILL_CLOUD_ANSIBLE_ROLES/migrations.yml"

# Install Flyway in the image
RUN ansible-playbook $ANSIBLE_OPTS -e flyway_owner=$TOMCAT_OWNER -e flyway_group=$TOMCAT_GROUP $KILLBILL_CLOUD_ANSIBLE_ROLES/flyway.yml

# Install Logtstash dependencies
ENV LOGSTASH_ENABLED=true
RUN ansible-playbook $ANSIBLE_OPTS $KILLBILL_CLOUD_ANSIBLE_ROLES/killbill_json_logging.yml --tags download

# Run kpm install and start Tomcat
CMD ["/var/lib/killbill/killbill.sh"]
