#!/bin/bash

# DOC: https://hub.docker.com/_/redis/

cat <<EOF > /etc/systemd/system/ns-redis.service
# ns-redis.service

[Unit]
Description=Podman ns-redis.service
Documentation=man:podman-generate-systemd(1)
Wants=network.target
After=network-online.target

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/ns-redis.pid %t/ns-redis.ctr-id
ExecStart=/usr/bin/podman run --conmon-pidfile %t/ns-redis.pid --cidfile %t/ns-redis.ctr-id --cgroups=no-conmon --replace -d -p 127.0.0.1:6379:6379 --volume /var/lib/nethserver/redis/data:/data:Z --name ns-redis docker.io/redis:6-alpine --appendonly yes
ExecStop=/usr/bin/podman stop --ignore --cidfile %t/ns-redis.ctr-id -t 10
ExecStopPost=/usr/bin/podman rm --ignore -f --cidfile %t/ns-redis.ctr-id
PIDFile=%t/ns-redis.pid
Type=forking

[Install]
WantedBy=multi-user.target default.target
EOF
restorecon /etc/systemd/system/ns-redis.service

systemctl daemon-reload
systemctl enable --now ns-redis.service
