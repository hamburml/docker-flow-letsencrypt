docker-flow-letsencrypt
==================

* [Introduction](#introduction)
* [How it's done](#how)
* [Usage](#usage)
* [Feedback and Contribution](#feedback-and-contribution)

## Introduction

This project is compatible with Docker: Flow Proxy and Docker: Swarm-Listener from https://github.com/vfarcic/docker-flow-proxy.
It uses certbot to create and renew https certificates for your domains and stores the certificates inside /etc/letsencrypt on the running docker host (you should run the service always on the same host).

## [How it's done](#how)

This docker image uses certbot, curl and cron to create and renew your letsencrypt certificates.
    

## Usage

### Build
```
docker build -t hamburml/cron-test .
```

### Docker Service

```
docker service create --name letsencrypt-companion \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath.1=/.well-known/acme-challenge \
    --label com.df.servicePath.2=/.well-known/acme-challenge \
    -e DOMAIN="haembi.de,www.haembi.de,www.michael-hamburger.de,michael-hamburger.de,owncloud.haembi.de" \
    -e CERTBOTEMAIL="michael.hamburger@mail.de" \
    -e PROXY_ADDRESS="proxy" \
    --network proxy \
    --label com.df.port.1=80 \
    --label com.df.port.2=443 \
    --label com.df.srcPort.1=80 \
    --label com.df.srcPort.2=443 \
    --mount type=bind,source=/etc/letsencrypt,destination=/etc/letsencrypt hamburml/docker-flow-letsencrypt
```

## Feedback and Contribution
