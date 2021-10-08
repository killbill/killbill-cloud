# Shell image that installs Kill Bill on startup
FROM killbill/base
LABEL maintainer="killbilling-users@googlegroups.com"

ENV KILLBILL_INSTALL_DIR=/var/lib/killbill

RUN sudo mkdir -p $KILLBILL_INSTALL_DIR $KILLBILL_INSTALL_DIR/bundles $KILLBILL_INSTALL_DIR/config
RUN sudo chown -R $TOMCAT_OWNER:$TOMCAT_GROUP $KILLBILL_INSTALL_DIR

# Default configuration options
ENV KB_org_killbill_osgi_bundle_install_dir=$KILLBILL_INSTALL_DIR/bundles
ENV KB_org_killbill_billing_osgi_bundles_jruby_conf_dir=$KILLBILL_INSTALL_DIR/config
ENV KB_org_killbill_server_baseUrl=http://$ENV_HOST_IP:8080
ENV KB_org_killbill_billing_plugin_kpm_kpmPath=$KPM_INSTALL_DIR/kpm-latest/kpm
ENV KB_org_killbill_billing_plugin_kpm_bundlesPath=$KILLBILL_INSTALL_DIR/bundles
ENV KB_org_killbill_security_shiroResourcePath=$KILLBILL_INSTALL_DIR/config/shiro.ini
ENV KB_ADMIN_PASSWORD=password

# Default kpm.yml, override as needed
COPY ./kpm.yml $KILLBILL_INSTALL_DIR
COPY ./setenv2.sh $CATALINA_BASE/bin
COPY ./killbill.sh $KILLBILL_INSTALL_DIR
COPY ./shiro.ini.template $KILLBILL_INSTALL_DIR/config

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

# Run kpm install (latest only) and start Tomcat
CMD ["/var/lib/killbill/killbill.sh"]
