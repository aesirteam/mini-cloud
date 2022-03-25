#!/bin/bash

set -eux

ip=$1
gw=$(echo $ip | awk -F. '{printf "%s.%s.%s.1",$1,$2,$3}')
dn=$HOSTNAME
domain=$dn.example.com

ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# extend the main partition to the end of the disk
# and extend the pve/data logical volume to use all
# the free space.
if growpart /dev/[vs]da 3; then
    pvresize /dev/[vs]da3
    lvextend -L +5G --resizefs /dev/pve/root
    lvextend --extents +100%FREE /dev/pve/data
fi

# configure the network for NATting.
ifdown vmbr0
cat >/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet manual

auto eth2
iface eth2 inet static
    address $2
    netmask 255.255.255.0

auto eth3
iface eth3 inet manual

auto vmbr0
iface vmbr0 inet static
    address $ip
    netmask 255.255.255.0
    bridge_ports eth1
    bridge_stp off
    bridge_fd 0
    post-up ip route add default via $gw

auto vmbr1
iface vmbr1 inet manual
    bridge_ports eth3
    bridge_stp off
    bridge_fd 0
EOF

sed -i -E "s,^[^ ]+( .*pve.*)\$,$ip\1," /etc/hosts
sed -i "s/pve.example.com/$domain/g;s/pve$/$dn/g" /etc/hosts
sed -i "s/pve/$dn/g" /etc/postfix/main.cf

cat >>/etc/issue <<EOF
    https://$ip:8006/
    https://$domain:8006/
EOF

ifup vmbr0
ifup eth1
ifup eth2
# ifup eth3
#iptables-save # show current rules.
killall agetty | true # force them to re-display the issue file.

mkdir -p /vagrant/shared
pushd /vagrant/shared

# create a self-signed certificate.
if [ ! -f $domain-crt.pem ]; then
    openssl genrsa \
        -out $domain-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $domain-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$domain" \
        -key $domain-key.pem \
        -out $domain-csr.pem
    openssl x509 -req -sha256 \
        -signkey $domain-key.pem \
        -extensions a \
        -extfile <(echo "[a]
            subjectAltName=DNS:$domain,IP:$ip
            extendedKeyUsage=critical,serverAuth
            ") \
        -days 365 \
        -in  $domain-csr.pem \
        -out $domain-crt.pem
    # openssl x509 \
    #     -in $domain-crt.pem \
    #     -outform der \
    #     -out $domain-crt.der
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $domain-crt.pem
fi

# install the certificate.
# see https://pve.proxmox.com/wiki/HTTPS_Certificate_Configuration_(Version_4.x_and_newer)
mkdir -p /etc/pve/nodes/$dn
cp $domain-key.pem "/etc/pve/nodes/$dn/pveproxy-ssl.key"
cp $domain-crt.pem "/etc/pve/nodes/$dn/pveproxy-ssl.pem"
systemctl restart pveproxy
# dump the TLS connection details and certificate validation result.
(printf 'GET /404 HTTP/1.0\r\n\r\n'; sleep .1) | openssl s_client -CAfile $domain-crt.pem -connect $domain:8006 -servername $domain

cat <<EOF
access the proxmox web interface at:
    https://$ip:8006/
    https://$domain:8006/
EOF
