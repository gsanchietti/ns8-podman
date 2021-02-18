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
      - "127.0.0.1:6379"

tls:
  certResolver: letsencrypt
  options: {}

certificatesResolvers:
  letsencrypt:
    acme:
      email: root@$HOST
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: http
      tlsChallenge: false
EOF

podman stop traefik
podman rm traefik


podman run --network=host --name traefik -d \
  -v "$HOME/traefik/config/acme:/etc/traefik/acme:Z" \
  -v "$HOME/traefik/config/traefik.yaml:/etc/traefik/traefik.yaml:Z" \
  docker.io/traefik:v2.4


