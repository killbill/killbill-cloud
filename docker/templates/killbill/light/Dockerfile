FROM killbill/killbill:0.20.11
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

# Install envsubst (see killbill.sh)
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y \
      gettext-base && \
    rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND teletype
USER tomcat

# Disable Ansible (requires /dev/shm)
ENV KPM_INSTALL_CMD /bin/true

# No JRuby plugin and no OSGI bundle, to keep memory usage low
RUN kpm uninstall kpm --destination=$KILLBILL_INSTALL_DIR/bundles
RUN rm -f $KILLBILL_INSTALL_DIR/bundles/platform/*

# Pre-expand the Kill Bill WAR
RUN cd $TOMCAT_HOME/webapps && \
    mkdir ROOT && \
    cd ROOT && \
    jar -xvf ../ROOT.war && \
    touch -r ../ROOT.war META-INF/war-tracker && \
    cd - && \
    rm -f ROOT.war && \
    cd -

# TODO
# * The SocketFactory jdbc driver doesn't seem to be working on Cloud Run
# * The Logback Stackdriver LoggingAppender isn't reliable
#
# Custom libraries
#COPY lib/*.jar $TOMCAT_HOME/webapps/ROOT/WEB-INF/lib/
# Hack for now...
#RUN cd $TOMCAT_HOME/webapps/ROOT/WEB-INF/lib/ && \
#    rm -f animal-sniffer-annotations-1.14.jar annotations-3.0.1u2.jar asm-5.0.3.jar commons-codec-1.9.jar commons-lang3-3.2.1.jar error_prone_annotations-2.1.3.jar google-api-services-sqladmin-v1beta4-rev20190510-1.28.0.jar j2objc-annotations-1.1.jar jackson-core-2.9.6.jar && \
#    cd -

# Add Kaui
COPY webapps/kaui.war $TOMCAT_HOME/webapps/kaui.war

# Pre-expand the Kaui WAR
RUN cd $TOMCAT_HOME/webapps && \
    mkdir kaui && \
    cd kaui && \
    jar -xvf ../kaui.war && \
    touch -r ../kaui.war META-INF/war-tracker && \
    cd - && \
    rm -f kaui.war && \
    cd -

# TODO See above
# Custom libraries
#COPY lib/*.jar $TOMCAT_HOME/webapps/kaui/WEB-INF/lib/
# Hack for now...
#RUN cd $TOMCAT_HOME/webapps/kaui/WEB-INF/lib/ && \
#    rm -f animal-sniffer-annotations-1.14.jar annotations-3.0.1u2.jar asm-5.0.3.jar commons-codec-1.9.jar commons-lang3-3.2.1.jar error_prone_annotations-2.1.3.jar google-api-services-sqladmin-v1beta4-rev20190510-1.28.0.jar j2objc-annotations-1.1.jar jackson-core-2.9.6.jar && \
#    cd -

# Note that classic configuration via environment variables won't work since Ansible isn't invoked
COPY webapp-context.xml $TOMCAT_HOME/webapps/ROOT/META-INF/context.xml
COPY webapp-context.xml $TOMCAT_HOME/webapps/kaui/META-INF/context.xml
COPY context.xml $TOMCAT_HOME/conf/context.xml
COPY server.xml $TOMCAT_HOME/conf/server.xml
COPY setenv.sh $TOMCAT_HOME/bin/setenv.sh
COPY logback.xml $KILLBILL_INSTALL_DIR/logback.xml
COPY killbill.properties.template $KILLBILL_INSTALL_DIR/killbill.properties.template
COPY killbill.sh $KILLBILL_INSTALL_DIR
