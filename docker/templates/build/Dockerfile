FROM ubuntu:16.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KILLBILL_HOME=/var/lib/killbill \
    KILLBILL_CONFIG=/etc/killbill

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      git \
      libcurl3 \
      libcurl4-openssl-dev \
      libmysqlclient-dev \
      libpq-dev \
      maven \
      mysql-client \
      openjdk-8-jdk \
      postgresql-client \
      software-properties-common \
      sudo \
      telnet \
      tomcat7 \
      unzip \
      zip \
      vim \
      less && \
    apt-add-repository -y ppa:rael-gc/rvm && \
    apt-get update && \
    apt-get install -y rvm && \
    rm -rf /var/lib/apt/lists/*

# Install JRuby as default (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.26/jruby-bin-1.7.26.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

RUN jruby -S gem install bundler jbundler therubyrhino

RUN ln -s /var/lib/jruby/bin/jruby /var/lib/jruby/bin/ruby

ENV JRUBY_OPTS=-J-Xmx1024m

# Add extra rubies
RUN /bin/bash -l -c "rvm install ruby-1.8.7-p374 && rvm use ruby-1.8.7-p374 && gem install bundler && \
                     rvm install ruby-2.2.2 && rvm use ruby-2.2.2 && gem install bundler && \
                     rvm install ruby-2.4.2 && rvm use ruby-2.4.2 && gem install bundler && \
                     rvm install jruby-9.1.14.0 && rvm use jruby-9.1.14.0 && gem install bundler"

# Add killbill user into sudo group
RUN adduser --disabled-password --gecos '' killbill && \
    usermod -aG sudo killbill && \
    echo 'killbill:killbill' | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p $KILLBILL_HOME $KILLBILL_CONFIG && \
    chown -R killbill:killbill $KILLBILL_CONFIG $KILLBILL_HOME /var/lib/jruby

USER killbill
WORKDIR $KILLBILL_HOME

ENV TERM=xterm

# Setup Maven
RUN mkdir -p /home/killbill/.m2
COPY ./settings.xml /home/killbill/.m2/settings.xml

# Setup git
RUN git config --global user.name "Kill Bill core team" && \
    git config --global user.email "contact@killbill.io" && \
    git config --global push.default simple && \
    git config --global credential.helper store

CMD ["bash"]
