FROM ubuntu:20.04 as builder-base
LABEL maintainer="killbilling-users@googlegroups.com"

USER root

ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=C
ENV LANG=en_US.UTF-8
ENV PYTHONIOENCODING=utf8

# Install convenient utilities
# https://github.com/moby/moby/issues/4032
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      ansible \
      # https://github.com/tianon/docker-brew-ubuntu-core/issues/59
      apt-utils \
      curl \
      # For envsubst
      gettext-base \
      git \
      less \
      libapr1 \
      mysql-client \
      net-tools \
      openjdk-8-jdk-headless \
      python3-lxml \
      sudo \
      telnet \
      unzip \
      # A bit large unfortunately (https://bugs.launchpad.net/ubuntu/+source/vim/+bug/1884583)
      vim && \
    rm -rf /var/lib/apt/lists/*

# Configure default JAVA_HOME path
RUN ln -s java-8-openjdk-amd64 /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV JSSE_HOME=$JAVA_HOME/jre/

# Create tomcat user into sudo group and reinitialize the password
# Note: the ansible role would take care of it, but that way, the ansible setup is done under the tomcat user
ENV TOMCAT_OWNER=tomcat
ENV TOMCAT_GROUP=tomcat
ENV TOMCAT_HOME=/var/lib/tomcat
RUN adduser $TOMCAT_OWNER \
            --home $TOMCAT_HOME \
            --disabled-password \
            --gecos '' && \
    usermod -aG sudo $TOMCAT_GROUP && \
    echo "$TOMCAT_OWNER:$TOMCAT_OWNER" | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set tomcat as the default user
USER $TOMCAT_OWNER
WORKDIR $TOMCAT_HOME

# Install ansible roles dependencies
ARG KILLBILL_CLOUD_VERSION
RUN ansible-galaxy collection install community.general && \
    ansible-galaxy install git+https://github.com/killbill/killbill-cloud.git,$KILLBILL_CLOUD_VERSION
ENV KILLBILL_CLOUD_ANSIBLE_ROLES=$TOMCAT_HOME/.ansible/roles/killbill-cloud/ansible
ENV ENV_HOST_IP=localhost
ENV ANSIBLE_OPTS="-i localhost, \
                  -e ansible_connection=local \
                  -e ansible_python_interpreter=/usr/bin/python3 \
                  -e java_home=$JAVA_HOME \
                  -e kpm_version=0.10.4 \
                  -vv"

# Install KPM
ENV NEXUS_URL=https://oss.sonatype.org
ENV NEXUS_REPOSITORY=releases
ENV KPM_INSTALL_DIR=/opt
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                     -e kpm_owner=$TOMCAT_OWNER \
                     -e kpm_group=$TOMCAT_GROUP \
                     -e nexus_url=$NEXUS_URL \
                     -e nexus_repository=$NEXUS_REPOSITORY \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/kpm.yml
ENV PATH="/opt/kpm-latest:${PATH}"

# Install Tomcat (without native libraries)
ENV CATALINA_BASE=$TOMCAT_HOME
ENV CATALINA_HOME=/usr/share/tomcat
ENV CATALINA_PID=$CATALINA_BASE/tomcat.pid
ENV CATALINA_TMPDIR=/var/tmp
ENV TOMCAT_INSTALL_DIR=/opt
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e tomcat_install_dir=$TOMCAT_INSTALL_DIR \
                     -e tomcat_native_libdir=$TOMCAT_NATIVE_LIBDIR \
                     -e tomcat_owner=$TOMCAT_OWNER \
                     -e tomcat_group=$TOMCAT_GROUP \
                     -e tomcat_home=$TOMCAT_HOME \
                     -e catalina_home=$CATALINA_HOME \
                     -e catalina_base=$CATALINA_BASE \
                     --skip-tags native \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/tomcat.yml

# Build Tomcat native libraries
FROM builder-base as builder-tomcat
USER $TOMCAT_OWNER
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e tomcat_install_dir=$TOMCAT_INSTALL_DIR \
                     -e tomcat_native_libdir=$TOMCAT_NATIVE_LIBDIR \
                     -e tomcat_owner=$TOMCAT_OWNER \
                     -e tomcat_group=$TOMCAT_GROUP \
                     -e tomcat_home=$TOMCAT_HOME \
                     -e catalina_home=$CATALINA_HOME \
                     -e catalina_base=$CATALINA_BASE \
                     -t native \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/tomcat.yml

# Final base image with Tomcat and KPM
FROM builder-base
COPY --from=builder-tomcat /usr/share/tomcat/native-jni-lib /usr/share/tomcat/native-jni-lib
# Start Tomcat
EXPOSE 8080
CMD ["/usr/share/tomcat/bin/catalina.sh", "run"]
