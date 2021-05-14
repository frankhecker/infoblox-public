#!/bin/sh
# configure_oph.sh: Configure Ubuntu for deployment of OPH container.

# NOTE: This script is run on the AWS Ubuntu instance, *not* locally.
# It can be run directly (using sudo) or passed as user data.

# Log output of script for troubleshooting.
exec >/var/log/configure_oph.log 2>&1
set -x

# Get the hostname and (primary) IP address for later use.
# NOTE: We use the source address used to connect to external hosts.
host_name=`hostname`
host_ip=`ip route get 1.1.1.1 | head -1 | cut -d' ' -f7`

# Get the IP address of the AWS DNS resolver.
# NOTE: This assumes that the system has only one network interface.
# We also assume that the VPC is at least a /24 CIDR block.
metadata_url=http://169.254.169.254/latest/meta-data
mac_id=`curl --no-progress-meter \
    ${metadata_url}/network/interfaces/macs \
    | tr -d '/'`
resolver_ip=`curl --no-progress-meter \
    ${metadata_url}/network/interfaces/macs/${mac_id}/vpc-ipv4-cidr-block \
    | sed -e 's:0/[0-9]*$:2:'`

# Upgrade Ubuntu to latest security and other fixes.
apt-get update
apt-get upgrade -y

# Install Docker.
apt-get install apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update
apt-cache policy docker-ce
apt-get install docker-ce -y
systemctl status docker

# Stop Ubuntu from listening on port 53 to avoid conflict with DFP.
# TODO: Generalize this to use correct resolver for other clouds.
sed -i.bak \
    -e "/^#*DNS=/s/^.*$/DNS=${resolver_ip}/" \
    -e '/^#*DNSStubListener=/s/^.*$/DNSStubListener=no/' \
    -e '/^#*ReadEtcHosts=/s/^.*$/ReadEtcHosts=yes/' \
    /etc/systemd/resolved.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Fix hosts file to eliminate sudo error message.
cat >>/etc/hosts <<EOF
${host_ip}  ${host_name}
EOF

# Switch sshd to use port 2022 to avoid conflict with OPH functions.
sed -i.bak \
    -e '/^\#Port 22$/s//Port 2022/' \
    /etc/ssh/sshd_config
# service sshd restart

# Add startup script to mark configuration as complete after reboot.
cat >/etc/systemd/system/configure_oph.service <<EOF
[Unit]
Description=Signal that configure_oph.sh script has run and system rebooted.

[Service]
ExecStart=touch /tmp/configure_oph.completed

[Install]
WantedBy=multi-user.target
EOF
systemctl enable configure_oph

# Reboot the system.
