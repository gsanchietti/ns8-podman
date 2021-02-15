#!/bin/bash

# DOC: https://hub.docker.com/_/redis/

N=ns-redis
DIR=/var/lib/nethserver/redis

# configure persistente dir
mkdir -p $DIR/data

podman pod stop $N-pod
podman pod rm $N-pod
        
podman pod create --name $N-pod -p 127.0.0.1:6379:6379

podman run -d --volume $DIR/data:/data:Z \
	--pod $N-pod --name $N docker.io/redis:6-alpine  --appendonly yes
