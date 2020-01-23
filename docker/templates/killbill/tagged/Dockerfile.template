FROM killbill/killbill
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# VERSION will be expanded in Makefile
ENV KILLBILL_VERSION __VERSION__

# Default kpm.yml, override as needed
COPY ./kpm.yml $KILLBILL_INSTALL_DIR

# Install Kill Bill
RUN kpm pull_kb_server_war --destination=/var/lib/tomcat/webapps/ROOT.war --bundles_dir=/var/lib/killbill/bundles $KILLBILL_VERSION

# Install default bundles
RUN kpm pull_defaultbundles --destination=/var/lib/killbill/bundles $KILLBILL_VERSION

# Install kpm plugin by default
RUN kpm pull_ruby_plugin kpm --destination=/var/lib/killbill/bundles $KILLBILL_VERSION
