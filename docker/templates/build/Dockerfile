FROM ubuntu:20.04
LABEL maintainer="killbilling-users@googlegroups.com"

USER root

ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=C
ENV LANG=en_US.UTF-8
ENV PYTHONIOENCODING=utf8

# Install build dependencies and convenient utilities
# https://github.com/moby/moby/issues/4032
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      # https://github.com/tianon/docker-brew-ubuntu-core/issues/59
      apt-utils \
      build-essential \
      curl \
      git \
      less \
      libaio1 \
      libapr1 \
      libcurl4 \
      libcurl4-openssl-dev \
      libmysqlclient-dev \
      libnuma1 \
      libpq-dev \
      maven \
      mysql-client \
      net-tools \
      openjdk-11-jdk-headless \
      postgresql-client \
      python3-lxml \
      software-properties-common \
      sudo \
      telnet \
      unzip \
      zip \
      vim && \
    apt-add-repository -y ppa:rael-gc/rvm && \
    rm -rf /var/lib/apt/lists/*

# Configure default JAVA_HOME path
RUN update-java-alternatives -s java-1.11.0-openjdk-amd64
RUN rm -f /usr/lib/jvm/default-java && ln -s java-11-openjdk-amd64 /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV JSSE_HOME=$JAVA_HOME/jre/

# Create killbill user into sudo group and reinitialize the password
ENV KILLBILL_HOME=/var/lib/killbill
RUN adduser killbill \
            --home $KILLBILL_HOME \
            --disabled-password \
            --gecos '' && \
    usermod -aG sudo killbill && \
    echo "killbill:killbill" | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install RVM
RUN apt-get update && \
    apt-get install --no-install-recommends -y rvm && \
    rm -rf /var/lib/apt/lists/*

# Add extra rubies
RUN /bin/bash -l -c "rvm install 2.2.2 && rvm install 2.4.2 && rvm install jruby-9.1.14.0"

# Set killbill as the default user
USER killbill
WORKDIR $KILLBILL_HOME
ENV TERM=xterm

# Setup Maven
RUN mkdir -p $KILLBILL_HOME/.m2
COPY ./settings.xml $KILLBILL_HOME/.m2/settings.xml

# Setup git
RUN git config --global user.name "Kill Bill core team" && \
    git config --global user.email "contact@killbill.io" && \
    git config --global push.default simple && \
    git config --global credential.helper store

CMD ["bash"]
