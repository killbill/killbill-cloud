FROM killbill/kaui
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# VERSION will be expanded in Makefile
ENV KAUI_VERSION __VERSION__

# Default kpm.yml, override as needed
COPY ./kpm.yml $KAUI_INSTALL_DIR

# Install Kaui
RUN kpm pull_kaui_war --destination=/var/lib/tomcat/webapps/ROOT.war --sha1_file=/var/lib/kaui/sha1.yml $KAUI_VERSION

