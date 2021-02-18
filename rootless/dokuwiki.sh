#!/bin/bash

# DOC: https://github.com/bitnami/bitnami-docker-dokuwiki#configuration

N=dokuwiki

# configure environment variable
# example: redis-cli hmset service/dokuwiki/env DOKUWIKI_USER admin
i=0
envs=''
while read -r line
do
    if [[ -z "$line" ]]; then
        continue
    fi
    if [[ $i%2 -gt 0 ]]; then
        envs="$envs=$line"
    else
        envs="$envs -e $line"
    fi
    i=$((i+1))
done < <(podman run -it --network host --rm docker.io/redis redis-cli --raw hgetall service/dokuwiki/env)

# configure persistente dir
mkdir -p $HOME/dokuwiki/data
podman unshare chown 1001:1001 /home/dokuwiki/dokuwiki/data/
vols=" --volume $HOME/dokuwiki/data:/bitnami/dokuwiki:Z"

# set virtual host name
HOST=dokuwiki.$(hostname -f)

podman stop $N
podman rm $N

podman run --network host -d $envs $vols --name $N docker.io/bitnami/dokuwiki:latest

podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/services/$N/loadbalancer/servers/0/url http://127.0.0.1:8080
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-http/service $N
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-http/entrypoints http,https
podman run -it --network host --rm docker.io/redis redis-cli SET traefik.http/routers/$N-http/rule "Host(\`$HOST\`)"
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/entrypoints http,https
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/rule "Host(\`$HOST\`)"
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/tls true
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/service $N
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/tls/certresolver letsencrypt
podman run -it --network host --rm docker.io/redis redis-cli SET traefik/http/routers/$N-https/tls/domains/0/main $HOST
