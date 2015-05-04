FROM ubuntu:14.04
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

ENV KILLBILL_HOME /var/lib/killbill
ENV KILLBILL_CONFIG /etc/killbill

# Install Kill Bill dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      curl \
      git \
      maven \
      mysql-client \
      openjdk-7-jdk \
      sudo \
      telnet \
      tomcat7 \
      unzip && \
    rm -rf /var/lib/apt/lists/*

# Install JRuby (the Ubuntu JRuby package is 1.5.6!)
RUN mkdir -p /var/lib/jruby \
    && curl -SL http://jruby.org.s3.amazonaws.com/downloads/1.7.16/jruby-bin-1.7.16.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/jruby
ENV PATH /var/lib/jruby/bin:$PATH

# Install Bundler
RUN jruby -S gem install bundler
# Install JBundler
RUN jruby -S gem install jbundler
# Install a JavaScript runtime
RUN jruby -S gem install therubyrhino

# Install Maven (the Ubuntu Maven package is 3.0.5)
RUN mkdir -p /var/lib/maven \
    && curl -SL http://mirror.metrocast.net/apache/maven/maven-3/3.3.1/binaries/apache-maven-3.3.1-bin.tar.gz \
    | tar -z -x --strip-components=1 -C /var/lib/maven
ENV PATH /var/lib/maven/bin:$PATH

# Add killbill user into sudo group
RUN adduser --disabled-password --gecos '' killbill
RUN usermod -aG sudo killbill
RUN echo 'killbill:killbill' | chpasswd

RUN mkdir -p $KILLBILL_HOME $KILLBILL_CONFIG
RUN chown -R killbill:killbill $KILLBILL_CONFIG $KILLBILL_HOME /var/lib/jruby

COPY ./setup.sh /etc/init.d/setup.sh
RUN chmod +x /etc/init.d/setup.sh

USER killbill
WORKDIR $KILLBILL_HOME

# Setup Maven
RUN mkdir -p /home/killbill/.m2
COPY ./settings.xml /home/killbill/.m2/settings.xml

# Setup git
RUN git config --global user.name "Kill Bill core team"
RUN git config --global user.email "contact@killbill.io"
RUN git config --global push.default simple

# Setup our repositories
RUN /etc/init.d/setup.sh

CMD ["bash"]
