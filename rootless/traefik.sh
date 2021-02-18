#!/bin/bash

HOST=$(hostname -f)

mkdir -p $HOME/traefik/config/acme

cat <<EOF > $HOME/traefik/config/traefik.yaml
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
  redis:
    endpoints:
      - "redis:6379"

tls:
  certResolver: letsencrypt
  options: {}

certificatesResolvers:
  letsencrypt:
    acme:
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      email: root@$HOST
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: http
      tlsChallenge: false
EOF

podman stop traefik
podman rm traefik


podman run --network nethserver --name traefik -d -p 8080:8080 -p 80:80 \
  -v "$HOME/traefik/config/acme:/etc/traefik/acme:Z" \
  -v "$HOME/traefik/config/traefik.yaml:/etc/traefik/traefik.yaml:Z" \
  docker.io/traefik:v2.4


