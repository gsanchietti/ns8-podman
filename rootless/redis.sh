#!/bin/bash

XDG_RUNTIME_DIR=/run/user/$(id -u)

mkdir -p ~/redis/data

podman stop redis
podman rm redis
podman run --name redis  -d -p 127.0.0.1:6379:6379 --volume ~/redis/data/:/data:Z docker.io/redis:6-alpine --appendonly yes
