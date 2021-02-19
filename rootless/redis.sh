#!/bin/bash

XDG_RUNTIME_DIR=/run/user/$UID
export XDG_RUNTIME_DIR

SYSTEMD_DIR=$HOME/.config/systemd/user
mkdir -p $SYSTEMD_DIR
mkdir -p ~/redis/data

podman stop redis
podman rm redis

podman volume create redis-data

podman run --name redis  -d --log-driver journald --network=host --volume redis-data:/data:Z docker.io/redis:6-alpine --appendonly yes

pushd $SYSTEMD_DIR
podman generate systemd --new --name redis  --files
popd
systemctl --user enable container-redis.service

