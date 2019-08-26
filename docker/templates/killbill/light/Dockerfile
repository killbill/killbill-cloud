FROM killbill/killbill:0.20.11
MAINTAINER Kill Bill core team <killbilling-users@googlegroups.com>

RUN kpm uninstall kpm --destination=/var/lib/killbill/bundles

ENV TOMCAT_JAVA_XMS 1024m
ENV TOMCAT_JAVA_XMX 1792m
ENV TOMCAT_JAVA_NEW_SIZE 100m
ENV TOMCAT_JAVA_MAX_NEW_SIZE 768m
