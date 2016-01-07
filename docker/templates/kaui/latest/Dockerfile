FROM killbill/base
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

USER root

# Default local and non multi-tenant properties
ENV KAUI_URL http://127.0.0.1:8080
ENV KAUI_API_KEY bob
ENV KAUI_API_SECRET lazar

ENV KAUI_CONFIG_DAO_URL jdbc:mysql://localhost:3306/kaui
ENV KAUI_CONFIG_DAO_USER kaui
ENV KAUI_CONFIG_DAO_PASSWORD kaui
ENV KAUI_CONFIG_DAO_ADAPTER jdbcmysql

ENV KAUI_CONFIG_DEMO false

COPY ./kaui.sh /etc/init.d/kaui.sh
RUN chmod +x /etc/init.d/kaui.sh

USER tomcat7

COPY ./kpm.yml.erb $KILLBILL_CONFIG

CMD ["/etc/init.d/kaui.sh", "run"]
