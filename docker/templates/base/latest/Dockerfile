# Base image with Tomcat and KPM
FROM ubuntu:16.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

USER root

# Install Kill Bill dependencies and useful tools
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y \
      apt-utils \
      curl \
      dpkg-dev \
      gcc \
      git \
      less \
      libapr1 \
      libapr1-dev \
      libssl-dev \
      make \
      mysql-client \
      net-tools \
      openjdk-8-jdk \
      python-pip \
      sudo \
      telnet \
      unzip \
      vim && \
    rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND teletype

# Configure default JAVA_HOME path
RUN ln -s java-8-openjdk-amd64 /usr/lib/jvm/default-java
ENV JAVA_HOME /usr/lib/jvm/default-java
ENV JSSE_HOME $JAVA_HOME/jre/

# Install latest Ansible version (deb package is too old)
RUN python -m pip install --upgrade pip && \
    pip install setuptools --upgrade && \
    pip install ansible

# Add tomcat user
ENV TOMCAT_OWNER tomcat
ENV TOMCAT_GROUP tomcat
ENV TOMCAT_HOME /var/lib/tomcat
RUN adduser $TOMCAT_OWNER \
            --home $TOMCAT_HOME \
            --disabled-password \
            --gecos ''

# Add tomcat user into sudo group and reinitialize the password
RUN usermod -aG sudo $TOMCAT_GROUP && \
    echo "$TOMCAT_OWNER:$TOMCAT_OWNER" | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $TOMCAT_OWNER
WORKDIR $TOMCAT_HOME

# Install roles dependencies
RUN mkdir -p $TOMCAT_HOME/.ansible && \
    touch $TOMCAT_HOME/.ansible_galaxy && \
    chown tomcat $TOMCAT_HOME/.ansible && \
    chown tomcat $TOMCAT_HOME/.ansible_galaxy
ARG KILLBILL_CLOUD_VERSION
RUN ansible-galaxy install git+https://github.com/killbill/killbill-cloud.git,$KILLBILL_CLOUD_VERSION

ENV KILLBILL_CLOUD_ANSIBLE_ROLES $TOMCAT_HOME/.ansible/roles/killbill-cloud/ansible

ENV ENV_HOST_IP localhost

ENV ANSIBLE_OPTS -i localhost, \
                 -e ansible_connection=local \
                 -e ansible_python_interpreter=/usr/bin/python \
                 -e java_home=$JAVA_HOME \
                 -vv

# Install KPM
ENV NEXUS_URL https://oss.sonatype.org
ENV NEXUS_REPOSITORY releases
ENV KPM_INSTALL_DIR /opt
ENV KPM_VERSION 0.7.2
RUN ansible-playbook $ANSIBLE_OPTS \
                     -e kpm_install_dir=$KPM_INSTALL_DIR \
                     -e nexus_url=$NEXUS_URL \
                     -e nexus_repository=$NEXUS_REPOSITORY \
                     -e kpm_version=$KPM_VERSION \
                     $KILLBILL_CLOUD_ANSIBLE_ROLES/kpm.yml
ENV PATH "/opt/kpm-${KPM_VERSION}-linux-x86_64:${PATH}"

# Install Tomcat
ENV CATALINA_BASE $TOMCAT_HOME
ENV CATALINA_HOME /usr/share/tomcat
ENV CATALINA_PID $CATALINA_BASE/tomcat.pid
ENV CATALINA_TMPDIR /var/tmp
ENV TOMCAT_INSTALL_DIR /opt
ENV TOMCAT_VERSION 8.5.16
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
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

# Start Tomcat
EXPOSE 8080
CMD ["/usr/share/tomcat/bin/catalina.sh", "run"]
