# ns8-podman

The following scripts will install podman and traefik on a CentOS 8 machine.

Current configuration:
- podman 3 installed from unstable repository to support traefik integration
- traefik is running as native service with unpriviliged user
- iptables instead of ngtables, all traffic is accepted

Modules like dokuwiki will use valid Let's Encrypt certificate, so the machine must:
- be accessible on port 80 from Let's Encrypt servers
- have a valid DNS public record for each service

## Install

```
dnf install git -y
git clone https://github.com/gsanchietti/ns8-podman.git
cd ns8-podman
./setup.sh
```

The setup script should be safe enough to be called multiple times.

Other files:
- ``dokuwiki.sh``: configure a dokuwiki instance with valid SSL certificate, persistence and redirection from HTTP to HTTPs
    Host for the dokuwiki is ``dokuwiki.<fqdn>``, make sure to have a valid DNS public record for it
  
