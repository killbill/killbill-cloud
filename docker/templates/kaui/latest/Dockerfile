# Shell image that installs Kaui on startup
FROM killbill/base
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KAUI_INSTALL_DIR /var/lib/kaui

RUN sudo mkdir -p $KAUI_INSTALL_DIR
RUN sudo chown -R $TOMCAT_OWNER:$TOMCAT_GROUP $KAUI_INSTALL_DIR

# Default kpm.yml, override as needed
COPY ./kpm.yml $KAUI_INSTALL_DIR

COPY ./kaui.sh $KAUI_INSTALL_DIR

ENV KPM_INSTALL_CMD ansible-playbook $ANSIBLE_OPTS  \
                                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                                     -e kpm_version=$KPM_VERSION \
                                     -e kpm_yml=$KAUI_INSTALL_DIR/kpm.yml \
                                     -e tomcat_owner=$TOMCAT_OWNER \
                                     -e tomcat_group=$TOMCAT_GROUP \
                                     -e catalina_base=$CATALINA_BASE \
                                     $KILLBILL_CLOUD_ANSIBLE_ROLES/kaui.yml
# Run kpm install and start Tomcat
CMD ["/var/lib/kaui/kaui.sh"]
