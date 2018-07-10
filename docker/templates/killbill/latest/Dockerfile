# Shell image that installs Kill Bill on startup
FROM killbill/base
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KILLBILL_INSTALL_DIR /var/lib/killbill

RUN sudo mkdir -p $KILLBILL_INSTALL_DIR $KILLBILL_INSTALL_DIR/bundles $KILLBILL_INSTALL_DIR/config
RUN sudo chown -R $TOMCAT_OWNER:$TOMCAT_GROUP $KILLBILL_INSTALL_DIR

# Default kpm.yml, override as needed
COPY ./kpm.yml $KILLBILL_INSTALL_DIR

# Default configuration options
ENV KILLBILL_BUNDLE_INSTALL_DIR $KILLBILL_INSTALL_DIR/bundles
ENV KILLBILL_JRUBY_CONF_DIR $KILLBILL_INSTALL_DIR/config
ENV KILLBILL_SERVER_BASE_URL http://$ENV_HOST_IP:8080

ENV KPM_INSTALL_CMD ansible-playbook $ANSIBLE_OPTS  \
                                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                                     -e kpm_version=$KPM_VERSION \
                                     -e kpm_yml=$KILLBILL_INSTALL_DIR/kpm.yml \
                                     -e kb_config_dir=$KILLBILL_INSTALL_DIR \
                                     -e kb_plugins_dir=$KILLBILL_INSTALL_DIR/bundles \
                                     -e tomcat_owner=$TOMCAT_OWNER \
                                     -e tomcat_group=$TOMCAT_GROUP \
                                     -e catalina_base=$CATALINA_BASE \
                                     $KILLBILL_CLOUD_ANSIBLE_ROLES/killbill.yml
# Run kpm install
CMD ["bash", "-c", "$KPM_INSTALL_CMD && $START_TOMCAT_CMD && touch $CATALINA_BASE/logs/killbill.out && tail -F $CATALINA_BASE/logs/killbill.out"]