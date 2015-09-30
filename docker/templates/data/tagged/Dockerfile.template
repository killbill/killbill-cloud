# docker build -t docker_dbdata .
# docker run --volumes-from demo_dbdata_1 -v $(pwd):/backup busybox tar cvf /backup/dbdata.tar /var/lib/mysql
FROM dockerfile/mariadb

ENV KILLBILL_VERSION __VERSION__

COPY ./$KILLBILL_VERSION/dbdata.tar.gz /data/dbdata.tar.gz
RUN gunzip /data/dbdata.tar.gz
COPY ./setup.sh /data/setup.sh
RUN chmod +x /data/setup.sh

CMD ["/data/setup.sh"]