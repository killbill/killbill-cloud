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
                  -vv"

# Install KPM
ENV NEXUS_URL=https://oss.sonatype.org
ENV NEXUS_REPOSITORY=releases
ENV KPM_INSTALL_DIR=/opt
ENV KPM_VERSION=0.10.1
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                     -e nexus_url=$NEXUS_URL \
                     -e nexus_repository=$NEXUS_REPOSITORY \
                     -e kpm_version=$KPM_VERSION \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/kpm.yml
RUN sudo chown -R $TOMCAT_OWNER:$TOMCAT_GROUP /opt/kpm-${KPM_VERSION}-linux-x86_64
ENV PATH="/opt/kpm-${KPM_VERSION}-linux-x86_64:${PATH}"

# Install Tomcat (without native libraries)
ENV CATALINA_BASE=$TOMCAT_HOME
ENV CATALINA_HOME=/usr/share/tomcat
ENV CATALINA_PID=$CATALINA_BASE/tomcat.pid
ENV CATALINA_TMPDIR=/var/tmp
ENV TOMCAT_INSTALL_DIR=/opt
ENV TOMCAT_VERSION=8.5.59
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e tomcat_version=$TOMCAT_VERSION \
                     -e tomcat_install_dir=$TOMCAT_INSTALL_DIR \
                     -e tomcat_native_libdir=$TOMCAT_NATIVE_LIBDIR \
                     -e tomcat_owner=$TOMCAT_OWNER \
                     -e tomcat_group=$TOMCAT_GROUP \
                     -e tomcat_home=$TOMCAT_HOME \
                     -e catalina_home=$CATALINA_HOME \
                     -e catalina_base=$CATALINA_BASE \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/tomcat.yml

# Install Tomcat (with native libraries)
FROM builder-base as builder-tomcat
USER root
# https://github.com/moby/moby/issues/4032
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      dpkg-dev \
      gcc \
      libapr1-dev \
      libssl-dev \
      make && \
    rm -rf /var/lib/apt/lists/*
USER $TOMCAT_OWNER
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e tomcat_version=$TOMCAT_VERSION \
                     -e tomcat_install_dir=$TOMCAT_INSTALL_DIR \
                     -e tomcat_native_libdir=$TOMCAT_NATIVE_LIBDIR \
                     -e tomcat_owner=$TOMCAT_OWNER \
                     -e tomcat_group=$TOMCAT_GROUP \
                     -e tomcat_home=$TOMCAT_HOME \
                     -e catalina_home=$CATALINA_HOME \
                     -e catalina_base=$CATALINA_BASE \
                     -e apr_config_path="$(which apr-1-config)" \
                     -e gnu_arch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/tomcat.yml

# Final base image with Tomcat and KPM
FROM builder-base
COPY --from=builder-tomcat /usr/share/tomcat/native-jni-lib /usr/share/tomcat/native-jni-lib
# Start Tomcat
EXPOSE 8080
CMD ["/usr/share/tomcat/bin/catalina.sh", "run"]
