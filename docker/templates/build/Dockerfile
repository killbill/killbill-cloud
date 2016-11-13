FROM ubuntu:16.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KILLBILL_HOME=/var/lib/killbill \
    KILLBILL_CONFIG=/etc/killbill

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      curl \
      git \
      maven \
      mysql-client \
      openjdk-8-jdk \
      sudo \
      telnet \
      tomcat7 \
      unzip \
      zip && \
    rm -rf /var/lib/apt/lists/*

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.26/jruby-bin-1.7.26.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

RUN jruby -S gem install bundler jbundler therubyrhino

# Add killbill user into sudo group
RUN adduser --disabled-password --gecos '' killbill && \
    usermod -aG sudo killbill && \
    echo 'killbill:killbill' | chpasswd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p $KILLBILL_HOME $KILLBILL_CONFIG && \
    chown -R killbill:killbill $KILLBILL_CONFIG $KILLBILL_HOME /var/lib/jruby

COPY ./setup.sh /etc/init.d/setup.sh
RUN chmod +x /etc/init.d/setup.sh

USER killbill
WORKDIR $KILLBILL_HOME

# Setup Maven
RUN mkdir -p /home/killbill/.m2
COPY ./settings.xml /home/killbill/.m2/settings.xml

# Setup git
RUN git config --global user.name "Kill Bill core team" && \
    git config --global user.email "contact@killbill.io" && \
    git config --global push.default simple

# Setup our repositories
RUN /etc/init.d/setup.sh

CMD ["bash"]
