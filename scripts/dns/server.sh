#!/usr/bin/env bash
DOMAIN=$1
SERVER_IP=$(hostname -I|awk '{print $1}')
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload

sudo apt -y install bind9 bind9-utils resolvconf
sudo mkdir -p /etc/bind/zones

cat <<EOF | sudo tee /etc/bind/zones/db.$DOMAIN
\$TTL	604800
@	IN	SOA	ns.$DOMAIN	admin.$DOMAIN. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	ns.$DOMAIN
@	IN	A	127.0.0.1
@	IN	AAAA	::1
ns.$DOMAIN	IN	A	$SERVER_IP
$DOMAIN	IN	A	$SERVER_IP
k8scp	IN	A	$SERVER_IP
EOF

cat <<EOF | sudo tee /etc/bind/named.conf.local
zone "$DOMAIN"{
	type master;
	file "/etc/bind/zones/db.$DOMAIN";
};
EOF

cat <<EOF | sudo tee /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";
    recursion yes;
    allow-recursion { any; };
    listen-on { $SERVER_IP; };
    allow-transfer { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
        114.114.114.114;
    };
    listen-on-v6 { any; };
};
EOF

sudo systemctl restart bind9

cat <<EOF | sudo tee /etc/resolvconf/resolv.conf.d/head
nameserver $SERVER_IP
EOF

sudo resolvconf -u