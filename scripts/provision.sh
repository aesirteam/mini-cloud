#!/bin/bash
set -eux

ip=$PVE_CLUSTER_ADDR
domain=$(hostname --fqdn)
dn=$(hostname)

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
    address $STORAGE_CLUSTER_ADDR
    netmask 255.255.255.0

auto vmbr0
iface vmbr0 inet static
    address $ip
    netmask 255.255.255.0
    bridge_ports eth1
    bridge_stp off
    bridge_fd 0
    # enable IP forwarding. needed to NAT and DNAT.
    post-up   echo 1 >/proc/sys/net/ipv4/ip_forward
    post-up   dnsmasq -u root --strict-order --bind-interfaces \
      --pid-file=/var/run/vmbr0.pid \
      --conf-file= \
      --except-interface=lo \
      --interface vmbr0  \
      --dhcp-range 10.10.10.2,10.10.10.254,255.255.255.0 \
      --dhcp-option=3,$ip \
      --dhcp-option=6,192.168.121.1 \
      --dhcp-leasefile=/var/run/vmbr0.leases
    # NAT through eth0.
    post-up   iptables -t nat -A POSTROUTING -s '$ip/24' ! -d '$ip/24' -o eth0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '$ip/24' ! -d '$ip/24' -o eth0 -j MASQUERADE
EOF
sed -i -E "s,^[^ ]+( .*pve.*)\$,$ip\1," /etc/hosts

cat >>/etc/issue <<EOF
    https://$ip:8006/
    https://$domain:8006/

EOF
ifup vmbr0
ifup eth1
ifup eth2
iptables-save # show current rules.
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
    openssl x509 \
        -in $domain-crt.pem \
        -outform der \
        -out $domain-crt.der
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
