#!/bin/bash

# DOC: https://docs.requarks.io/install/docker

N=wikijs

# configure environment variable
# example: redis-cli hmset service/wikijs/env DOKUWIKI_USER admin
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
done < <(redis-cli --raw hgetall service/wikijs/env)

# configure persistente dir
# expected format: /path/:uid:gid
# example: redis-cli SADD service/wikijs/paths /var/lib/nethserver/wikijs:1001:1001
paths=''
while read -r line
do
    path=$(echo $line | cut -d':' -f1)
    uid_gid=$(echo $line | cut -d':' -f2,3)

    mkdir -p $path
    chown $uid_gid $path
done < <(redis-cli --raw SMEMBERS service/wikijs/paths)

# map volumes
# expected format: host_path:container:path
# example: redis-cli SADD service/wikijs/volumes /var/lib/nethserver/wikijs:/bitnami/wikijs
vols=''
while read -r line
do
    vols="$vols --volume $line:Z "
done < <(redis-cli --raw  SMEMBERS service/wikijs/volumes)

# set virtual host name
# example: redis-cli SET service/wikijs/hostname mywiki.nethserver.org
HOST=$(redis-cli --raw GET service/wikijs/hostname)
if [ -z "$HOST" ]; then
    HOST=wikijs.$(hostname -f)
fi

podman pod create --name $N-pod

podman run -d $envs \
    $vols \
    --pod $N-pod --name $N-db docker.io/postgres:11-alpine


podman run -d $envs \
	-l "traefik.http.services.$N.loadbalancer.server.port=3000" \
	-l "traefik.http.routers.$N-http.entrypoints=http,https" \
	-l "traefik.http.routers.$N-http.rule=Host(\`$HOST\`)" \
	-l "traefik.http.middlewares.http-to-https.redirectscheme.scheme=https" \
	-l "traefik.http.routers.$N-http.middlewares=http-to-https@docker" \
	-l "traefik.http.routers.$N-https.entrypoints=http,https" \
	-l "traefik.http.routers.$N-https.rule=Host(\`$HOST\`)" \
	-l "traefik.http.routers.$N-https.tls=true" \
	-l "traefik.http.routers.$N-https.tls.certresolver=letsencrypt" \
	-l "traefik.http.routers.$N-https.tls.domains[0].main=$HOST" \
	--pod $N-pod --name $N docker.io/requarks/wiki:2
