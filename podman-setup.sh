#!/bin/bash

DOMAIN=$(hostname -d)

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

cat <<EOF >> /etc/sysctl.d/podman.conf
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Install podman (unstable release)
# See https://podman.io/getting-started/installation
dnf -y module disable container-tools
dnf -y install 'dnf-command(copr)'
dnf -y copr enable rhcontainerbot/container-selinux
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:testing.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/testing/CentOS_8/devel:kubic:libcontainers:testing.repo
dnf -y install podman
dnf -y update


# Install traefik
if [ ! -f /usr/local/bin/traefik ]; then
    dnf -y install wget
    wget https://github.com/traefik/traefik/releases/download/v2.4.2/traefik_v2.4.2_linux_amd64.tar.gz
    tar xvzf traefik_v2.4.2_linux_amd64.tar.gz
    mv traefik /usr/local/bin
    rm -f traefik_v2.4.2_linux_amd64.tar.gz
fi

# Configure traefik
setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik
groupadd -r traefik
useradd \
  -g traefik --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system -r traefik

mkdir -p /etc/traefik/acme
chown -R root:root /etc/traefik
chown -R traefik:traefik /etc/traefik/acme

cat <<EOF > /etc/traefik/traefik.yaml
defaultEntryPoints:
  - http
  - https

file: {}

log:
  level: DEBUG

accessLog: {}

entryPoints:
  http:
   address: ":80"
  https:
   address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/podman/podman.sock"

tls:
  certResolver: letsencrypt
  options: {}

certificatesResolvers:
  letsencrypt:
    acme:
      email: rood@$DOMAIN
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: http
EOF
chown root:root /etc/traefik/traefik.yaml
chmod 644 /etc/traefik/traefik.yaml

touch /etc/traefik/acme/acme.json
chown traefik:traefik /etc/traefik/acme/acme.json
chmod 600 /etc/traefik/acme/acme.json
chcon system_u:object_r:etc_t:s0 /etc/traefik/acme/acme.json
cat <<EOF > /etc/systemd/system/traefik.service
[Unit]
Description=traefik proxy
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal

; User and group the process will run as.
User=traefik
Group=traefik

; Always set "-root" to something safe in case it gets forgotten in the traefikfile.
ExecStart=/usr/local/bin/traefik --configfile=/etc/traefik/traefik.yaml

; Limit the number of file descriptors; see 'man systemd.exec' for more limit settings.
LimitNOFILE=1048576

; Use private /tmp and /var/tmp, which are discarded after traefik stops.
PrivateTmp=true
; Use a minimal /dev (May bring additional security if switched to 'true', but it may not work on Raspberry Pi's or other devices, so it has been disabled in this dist.)
PrivateDevices=false
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
; … except /etc/ssl/traefik, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWriteDirectories=/etc/traefik/acme

; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by traefik. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Configure SELinux for traefik
cat <<EOF > traefik.te
module traefik 1.0;

require {
	type init_t;
	type admin_home_t;
	class file execute;
}

#============= init_t ==============
allow init_t admin_home_t:file execute;
EOF

checkmodule -M -m -o traefik.mod traefik.te
semodule_package -o traefik.pp -m traefik.mod
semodule -X 300 -i traefik.pp

# Enable podman socket for traefik (used for autoconfig with labels)
mkdir -p /etc/systemd/system/podman.socket.d
cat <<EOF > /etc/systemd/system/podman.socket.d/override.conf
[Socket]
Group=traefik
EOF
systemctl enable --now  podman.socket

systemctl daemon-reload
systemctl enable --now traefik.service
