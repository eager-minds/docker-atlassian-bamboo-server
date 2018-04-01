#!/bin/bash
set -euo pipefail

# Setup Catalina Opts
: ${CATALINA_CONNECTOR_PROXYNAME:=}
: ${CATALINA_CONNECTOR_PROXYPORT:=}
: ${CATALINA_CONNECTOR_SCHEME:=http}
: ${CATALINA_CONNECTOR_SECURE:=false}
: ${CATALINA_CONNECTOR_PATH:=}

: ${CATALINA_OPTS:=}

CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyName=${CATALINA_CONNECTOR_PROXYNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyPort=${CATALINA_CONNECTOR_PROXYPORT}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorScheme=${CATALINA_CONNECTOR_SCHEME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=${CATALINA_CONNECTOR_SECURE}"

export CATALINA_OPTS

# Bamboo proxy
#if [ "$(stat -c "%Y" "${BAMBOO_INSTALL}/conf/server.xml")" -eq "0" ]; then
  if [ -n "${CATALINA_CONNECTOR_PROXYNAME}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8085"]' --type "attr" --name "proxyName" --value "${CATALINA_CONNECTOR_PROXYNAME}" "${BAMBOO_INSTALL}/conf/server.xml"
  fi
  if [ -n "${CATALINA_CONNECTOR_PROXYPORT}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8085"]' --type "attr" --name "proxyPort" --value "${CATALINA_CONNECTOR_PROXYPORT}" "${BAMBOO_INSTALL}/conf/server.xml"
  fi
  if [ -n "${CATALINA_CONNECTOR_SCHEME}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8085"]' --type "attr" --name "scheme" --value "${CATALINA_CONNECTOR_SCHEME}" "${BAMBOO_INSTALL}/conf/server.xml"
  fi
  if [ "${CATALINA_CONNECTOR_SCHEME}" = "https" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8085"]' --type "attr" --name "secure" --value "true" "${BAMBOO_INSTALL}/conf/server.xml"
    xmlstarlet ed --inplace --pf --ps --update '//Connector[@port="8085"]/@redirectPort' --value "${CATALINA_CONNECTOR_PROXYPORT}" "${BAMBOO_INSTALL}/conf/server.xml"
  fi
  if [ -n "${CATALINA_CONNECTOR_PATH}" ]; then
    xmlstarlet ed --inplace --pf --ps --update '//Context/@path' --value "${CATALINA_CONNECTOR_PATH}" "${BAMBOO_INSTALL}/conf/server.xml"
  fi
#fi

# Start Confluence as the correct user
if [ "${UID}" -eq 0 ]; then
    echo "User is currently root. Will change directory ownership to ${RUN_USER}:${RUN_GROUP}, then downgrade permission to ${RUN_USER}"
    PERMISSIONS_SIGNATURE=$(stat -c "%u:%U:%a" "${BAMBOO_HOME}")
    EXPECTED_PERMISSIONS=$(id -u ${RUN_USER}):${RUN_USER}:700
    if [ "${PERMISSIONS_SIGNATURE}" != "${EXPECTED_PERMISSIONS}" ]; then
        chmod -R 700 "${BAMBOO_HOME}" &&
            chown -R "${RUN_USER}:${RUN_GROUP}" "${BAMBOO_HOME}"
    fi
    # Now drop privileges
    exec su -s /bin/bash "${RUN_USER}" -c "$BAMBOO_INSTALL/bin/start-bamboo.sh $@"
else
    exec "$BAMBOO_INSTALL/bin/start-bamboo.sh" "$@"
fi
