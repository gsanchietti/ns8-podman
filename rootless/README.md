# rootless

Tested on Fedora 33.

Podman running in rootless mode:
- every container has its own user
- traefik reads the dynamic configuration from redis
- containers talk to each other using host network

As root:
```
dnf install git -y
git clone https://github.com/gsanchietti/ns8-podman.git
cd ns8-podman/rootless
./setup.sh
useradd redis
useradd traefik
useradd dokuwiki

cp redis.sh /home/redis
cp traefik.sh /home/traefik
cp dokuwiki.sh /home/dokwuiki
```

Then enable redis and traefik:
```
loginctl enable-linger redis
su - redis
./redis.sh
exit

su - traefik
./traefik
exit
```

Start dokuwiki avaialble at `dokuwiki.<fqdn>`:
```
su - dokuwiki
./dokuwiki
```
