#!/usr/bin/env bash
export PATH=$PATH:/home/$(whoami)/.local/bin

DOMAIN_NAME=$1

sudo firewall-cmd --permanent --add-service=ldap
sudo firewall-cmd --permanent --add-service=ldaps
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

mkdir -p $HOME/configs/openldap
cat <<EOF | tee $HOME/configs/openldap/docker-compose.yaml
version: '2'
services:
  openldap:
    image: osixia/openldap:1.2.3
    restart: always
    environment:
      LDAP_LOG_LEVEL: "256"
      LDAP_ORGANISATION: "myCloud Inc."
      LDAP_DOMAIN: "$DOMAIN_NAME"
      LDAP_BASE_DN: ""
      LDAP_ADMIN_PASSWORD: "admin"
      LDAP_CONFIG_PASSWORD: "config"
      LDAP_READONLY_USER: "false"
      LDAP_READONLY_USER_USERNAME: "readonly"
      LDAP_READONLY_USER_PASSWORD: "readonly"
      LDAP_RFC2307BIS_SCHEMA: "false"
      LDAP_BACKEND: "mdb"
      LDAP_TLS: "true"
      LDAP_TLS_CRT_FILENAME: "ldap.crt"
      LDAP_TLS_KEY_FILENAME: "ldap.key"
      LDAP_TLS_CA_CRT_FILENAME: "ca.crt"
      LDAP_TLS_ENFORCE: "false"
      LDAP_TLS_CIPHER_SUITE: "SECURE256:-VERS-SSL3.0"
      LDAP_TLS_PROTOCOL_MIN: "3.1"
      LDAP_TLS_VERIFY_CLIENT: "demand"
      LDAP_REPLICATION: "false"
      #LDAP_REPLICATION_CONFIG_SYNCPROV: "binddn="cn=admin,cn=config" bindmethod=simple credentials=$LDAP_CONFIG_PASSWORD searchbase="cn=config" type=refreshAndPersist retry="60 +" timeout=1 starttls=critical"
      #LDAP_REPLICATION_DB_SYNCPROV: "binddn="cn=admin,$LDAP_BASE_DN" bindmethod=simple credentials=$LDAP_ADMIN_PASSWORD searchbase="$LDAP_BASE_DN" type=refreshAndPersist interval=00:00:00:10 retry="60 +" timeout=1 starttls=critical"
      #LDAP_REPLICATION_HOSTS: "#PYTHON2BASH:['ldap://ldap.example.org','ldap://ldap2.example.org']"
      KEEP_EXISTING_CONFIG: "false"
      LDAP_REMOVE_CONFIG_AFTER_SETUP: "true"
      LDAP_SSL_HELPER_PREFIX: "ldap"
    tty: true
    stdin_open: true
    volumes:
      - /var/lib/ldap
      - /etc/ldap/slapd.d
      - /container/service/slapd/assets/certs/
    ports:
      - "389:389"
      - "636:636"
    domainname: "$DOMAIN_NAME" # important: same as hostname
  
  phpldapadmin:
    image: osixia/phpldapadmin:latest
    restart: always
    environment:
      PHPLDAPADMIN_LDAP_HOSTS: "openldap"
      PHPLDAPADMIN_HTTPS: "false"
    ports:
      - "3000:80"
    depends_on:
      - openldap
EOF

docker-compose -f $HOME/configs/openldap/docker-compose.yaml up -d