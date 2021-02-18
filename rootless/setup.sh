#!/bin/bash

HOST=$(hostname -f)

# Configure firewall: disable ntftable and accept all traffic
dnf install -y iptables-services
systemctl disable firewalld
systemctl disable --now nftables

cat <<EOF > /etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF

systemctl enable --now iptables

cat <<EOF > /etc/sysctl.d/podman.conf
user.max_user_namespaces=28633
net.ipv4.ip_unprivileged_port_start=0
EOF
sysctl -p /etc/sysctl.d/podman.conf

# Install podman
# See https://podman.io/getting-started/installation
dnf -y module disable container-tools
dnf -y install 'dnf-command(copr)'
dnf -y copr enable rhcontainerbot/container-selinux
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:atable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/testing/CentOS_8/devel:kubic:libcontainers:testing.repo
dnf -y install podman
