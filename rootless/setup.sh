#!/bin/bash

cat <<EOF > /etc/sysctl.d/podman.conf
user.max_user_namespaces=28633
net.ipv4.ip_unprivileged_port_start=0
EOF
sysctl -p /etc/sysctl.d/podman.conf

# Install podman
dnf -y install podman
