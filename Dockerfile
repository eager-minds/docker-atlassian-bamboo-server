FROM openjdk:8-jdk-alpine
MAINTAINER Eager Minds

# Environment vars
ENV BAMBOO_HOME        /var/atlassian/application-data/bamboo
ENV BAMBOO_INSTALL     /opt/atlassian/bamboo
ENV BAMBOO_VERSION     6.4.1
ENV MYSQL_VERSION      5.1.45
ENV POSTGRES_VERSION   42.1.4

ENV RUN_USER           root
ENV RUN_GROUP          root

ARG DOWNLOAD_URL=http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_JAR=mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}-bin.jar
ARG OLD_POSTGRES_CONNECTOR_JAR=postgresql-42.0.0.jar
ARG POSTGRES_CONNECTOR_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-${POSTGRES_VERSION}.jar
ARG POSTGRES_CONNECTOR_JAR=postgresql-${POSTGRES_VERSION}.jar

# Print executed commands
RUN set -x

# Install requeriments
RUN apk update -qq
RUN update-ca-certificates
RUN apk add --no-cache   ca-certificates wget curl git git-daemon openssh bash procps openssl perl ttf-dejavu tini

# Bamboo set up
RUN rm -rf               /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/*
RUN mkdir -p             ${BAMBOO_HOME}
RUN chmod -R 700         ${BAMBOO_HOME}
RUN mkdir -p             ${BAMBOO_INSTALL}
RUN curl -Ls             ${DOWNLOAD_URL}         \
       | tar -xz         --strip-components=1    \
             -C          $BAMBOO_INSTALL
RUN ls -la               ${BAMBOO_INSTALL}

# Database connectors
RUN curl -Ls               "${MYSQL_CONNECTOR_DOWNLOAD_URL}"   \
     | tar -xz --directory "${BAMBOO_INSTALL}/lib"             \
                           "${MYSQL_CONNECTOR_JAR}"            \
                           --strip-components=1 --no-same-owner
RUN rm -f                  "${BAMBOO_INSTALL}/lib/${OLD_POSTGRES_CONNECTOR_JAR}"
RUN curl -Ls               "${POSTGRES_CONNECTOR_DOWNLOAD_URL}" -o "${BAMBOO_INSTALL}/lib/${POSTGRES_CONNECTOR_JAR}"

# Config
RUN echo -e                "\nbamboo.home=$BAMBOO_HOME" >> "${BAMBOO_INSTALL}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties"

USER root:root

# Expose HTTP and agent ports
EXPOSE 8085
EXPOSE 54663

VOLUME ["/var/atlassian/application-data/bamboo", "/opt/atlassian/bamboo/logs"]

WORKDIR $BAMBOO_HOME

COPY . /tmp
COPY "entrypoint.sh" "/"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh", "-fg"]
