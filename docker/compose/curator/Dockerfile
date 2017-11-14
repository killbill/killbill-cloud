FROM killbill/base:latest

USER root

# Install dependencies and useful tools
RUN apt-get update && \
    apt-get install -y \
      rsyslog \
      python-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

RUN pip install -U elasticsearch-curator

RUN touch /var/log/curator.log

ADD curator.sh /root/curator.sh
RUN chmod +x /root/curator.sh

ADD crontab /etc/cron.d/curator
RUN chmod 0644 /etc/cron.d/curator

RUN service rsyslog start

WORKDIR /etc/cron.d

CMD cron -L 15 && tail -f /var/log/curator.log