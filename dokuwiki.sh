#!/bin/bash

# DOC: https://github.com/bitnami/bitnami-docker-dokuwiki#configuration

N=ns-dokuwiki
HOST=dokuwiki.$(hostname -f)
DIR=/var/lib/nethserver/dokuwiki

# configure persistente dir
mkdir -p $DIR
chown 1001:1001 $DIR

podman pod stop $N-pod
podman pod rm $N-pod
        
podman pod create --name $N-pod

podman run -d -e DOKUWIKI_USERNAME=admin -e DOKUWIKI_PASSWORD=admin -e DOKUWIKI_WIKI_NAME="NS Dokuwiki" \
	-l "traefik.http.services.$N.loadbalancer.server.port=8080" \
	-l "traefik.http.routers.$N-http.entrypoints=http,https" \
	-l "traefik.http.routers.$N-http.rule=Host(\`$HOST\`)" \
	-l "traefik.http.middlewares.http-to-https.redirectscheme.scheme=https" \
	-l "traefik.http.routers.$N-http.middlewares=http-to-https@docker" \
	-l "traefik.http.routers.$N-https.entrypoints=http,https" \
	-l "traefik.http.routers.$N-https.rule=Host(\`$HOST\`)" \
	-l "traefik.http.routers.$N-https.tls=true" \
	-l "traefik.http.routers.$N-https.tls.certresolver=letsencrypt" \
	-l "traefik.http.routers.$N-https.tls.domains[0].main=$HOST" \
	--volume $DIR:/bitnami/dokuwiki:Z \
	--pod $N-pod --name $N docker.io/bitnami/dokuwiki:latest
