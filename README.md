# ns8-podman

The following scripts will install podman and traefik on a CentOS 8 machine.

Current configuration:
- podman 3 installed from unstable repository to support traefik integration
- traefik is running as native service with unpriviliged user
- use iptables instead of nftables, all traffic is accepted

Modules like dokuwiki will use valid Let's Encrypt certificate, so the machine must:
- be accessible on port 80 from Let's Encrypt servers
- have a valid public DNS record for each service

## Install

```
dnf install git -y
git clone https://github.com/gsanchietti/ns8-podman.git
cd ns8-podman
./setup.sh
```

The setup script should be safe enough to be called multiple times.

#### Redis

First, start redis by executing: `./redis.sh`

### Dokuwiki

Put the configuration on REDIS:
```
redis-cli hmset service/dokuwiki/env DOKUWIKI_USER admin
redis-cli SADD service/dokuwiki/paths /var/lib/nethserver/dokuwiki:1001:1001
redis-cli SADD service/dokuwiki/volumes /var/lib/nethserver/dokuwiki:/bitnami/dokuwiki
redis-cli SET service/dokuwiki/hostname mywiki.nethserver.org
```

Then start the pod: `./dokuwiki.sh`

The script will start a dokuwiki instance with valid SSL certificate, persistence and redirection from HTTP to HTTPs
Default host for the dokuwiki is ``dokuwiki.<fqdn>``, make sure to have a valid DNS public record for it.
  
