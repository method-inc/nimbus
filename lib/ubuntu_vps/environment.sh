#!/bin/bash

echo "adding keys to authorized_users..."
mkdir -p /root/.ssh
echo "{{authorizedKeys}}" > /root/.ssh/authorized_keys
chmod 0700 /root/.ssh

echo "updating system limits..."
ulimit -n 64000
sysctl -w fs.file-max=100000
echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

echo "updating system packages..."
cd /root
apt-get update --yes
apt-get upgrade --yes
apt-get install --yes build-essential git-core libssl-dev curl
apt-get install --yes python-setuptools sendmail upstart python-software-properties
apt-get install --yes imagemagick libmagickcore-dev libmagickwand-dev
apt-get install --yes graphicsmagick libgraphicsmagick1-dev
apt-get install --yes ntpdate

echo "updating system clock for UTC..."
echo 'UTC' > /etc/timezone
cp /usr/share/zoneinfo/'UTC' /etc/localtime
ntpdate pool.ntp.org &2>1

<% if (!obj.updateOnly) { %>
echo "configuring static IP..."
cat <<'EOF' > /etc/network/interfaces
# The loopback interface
auto lo
iface lo inet loopback

# Configuration for eth0 and aliases

# This line ensures that the interface will be brought up during boot.
auto eth0 eth0:0 eth0:1

# eth0 - This is the main IP address that will be used for most outbound connections.
# The address, netmask and gateway are all necessary.
iface eth0 inet static
address {{publicIP}}
netmask 255.255.255.0
gateway {{gatewayIP}}

<% if(typeof obj.privateIP !== 'undefined') { %>
# eth0:1 - Private IPs have no gateway (they are not publicly routable) so all you need to
# specify is the address and netmask.
iface eth0:1 inet static
address {{privateIP}}
netmask 255.255.128.0
<% } %>
EOF
<% } %>