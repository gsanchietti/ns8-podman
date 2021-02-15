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
As final stage, the script will spawn a redis instance using `./redis.sh`.

## Configure

The configuration is stored inside redis.
After adding the required configuration for each service, just execute `./apply-config`.

To enable a service:
```
redis-cli SET service/<service>/status enabled
./apply-config
```

To disable a service:
```
redis-cli SET service/<service>/status disabled
./apply-config
```

### Dokuwiki

Configure a [Dokuwiki]/https://www.dokuwiki.org/) instance.

Put the configuration on Redis:
```
redis-cli SET service/dokuwiki/status enabled
redis-cli hmset service/dokuwiki/env DOKUWIKI_USER admin DOKUWIKI_PASSWORD admin
redis-cli SADD service/dokuwiki/paths /var/lib/nethserver/dokuwiki:1001:1001
redis-cli SADD service/dokuwiki/volumes /var/lib/nethserver/dokuwiki:/bitnami/dokuwiki
redis-cli SET service/dokuwiki/hostname dokuwiki.$(hostname -f)
```

Then start the pod: `./dokuwiki.sh`

The script will start a dokuwiki instance with valid SSL certificate, persistence and redirection from HTTP to HTTPs
Default host for the dokuwiki is ``dokuwiki.<fqdn>``, make sure to have a valid DNS public record for it.

## Wiki.js

Configure a [Wiki.js](https://js.wiki/) instance with a Postgres database.

Put the configuration on Redis:
```
redis-cli SET service/wikijs/status enabled
redis-cli hmset service/wikijs/env POSTGRES_DB wiki POSTGRES_PASSWORD wikipass POSTGRES_USER wikijs DB_TYPE postgres DB_HOST ns-wikijs-db DB_PORT 5432 DB_USER wikijs DB_PASS wikipass DB_NAME wiki
redis-cli SADD service/wikijs/volumes db-data:/var/lib/postgresql/data
redis-cli SADD service/wikijs/paths /var/lib/nethserver/wikijs:root:root
redis-cli SET service/wikijs/hostname wikijs.$(hostname -f)
```

Then start the pod: `./wikijs.sh`

The script will start a dokuwiki instance with valid SSL certificate, persistence and redirection from HTTP to HTTPs
Default host for the wikijs is ``wikijs.<fqdn>``, make sure to have a valid DNS public record for it.
