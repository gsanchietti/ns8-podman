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
done < <(redis-cli --raw hgetall service/dokuwiki/env)

# configure persistente dir
mkdir -p $HOME/dokuwiki/data
chown 10001:10001: $HOME/dokuwiki/data
vols=" --volume $HOME/dokuwiki/data:/bitnami/dokuwiki:Z"

# set virtual host name
# example: redis-cli SET service/dokuwiki/hostname mywiki.nethserver.org
HOST=$(redis-cli --raw GET service/dokuwiki/hostname)
if [ -z "$HOST" ]; then
    HOST=dokuwiki.$(hostname -f)
fi

podman stop $N
podman rm $N

podman run --network nethserver -d $envs $vols --name $N docker.io/bitnami/dokuwiki:latest

podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/services/$N/loadbalancer/servers/0/url http://dokuwiki:8080
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-http/entrypoints http,https
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik.http/routers/$N-http/rule Host\(\'$HOST\'\)
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-https/entrypoints http,https
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-https/rule Host\(\`$HOST\`\)
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-https/tls true
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-https/tls/certresolver letsencrypt
podman run -it --network nethserver --rm docker.io/redis redis-cli -h redis SET traefik/http/routers/$N-https/tls/domains/0/main $HOST
 
