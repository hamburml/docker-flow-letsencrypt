docker-flow-letsencrypt
==================

* [Introduction](#introduction)
* [How does it work](#how-does-it-work)
* [Usage](#usage)
* [Feedback and Contribution](#feedback-and-contribution)

## Introduction

This project is compatible with [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy) and [Docker Flow: Swarm Listener](https://github.com/vfarcic/docker-flow-swarm-listener).
It uses certbot to create and renew https certificates for your domains and stores the certificates inside /etc/letsencrypt on the running docker host (you should run the service always on the same host).

https://hub.docker.com/r/hamburml/docker-flow-letsencrypt/

## How does it work

This docker image uses certbot, curl and cron to create and renew your letsencrypt certificates.
Through environment variables you can set the domains certbot should create certificates, which email should be used and the proxy_address.

When the image starts, the certbot.sh script runs and creates/renews the certificates. The script also combines the cert.pem, chain.pem and privkey.pem to a domainname.combined.pem file. This file is send via curl -i -XPUT to the proxy.
The script is also symlinked in /etc/cron.daily and cron runs via supervisord.

If you only want to test this image you should add ```-e CERTBOTMODE="staging"``` when creating the service to use the staging mode of letsencrypt.

## Usage

### Build
```
docker build -t hamburml/docker-flow-letsencrypt .
```

### Docker Service

```
docker service create --name letsencrypt-companion \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/.well-known/acme-challenge \
    --label com.df.port=80 \
    -e DOMAIN_1="('domain1.de' 'www.domain1.de' 'subdomain1.domain1.de')"\
    -e DOMAIN_2="('domain2.de' 'www.domain2.de')"\
    -e DOMAIN_COUNT=2\
    -e CERTBOTEMAIL="michael.hamburger@mail.de" \
    -e PROXY_ADDRESS="proxy" \
    --network proxy \
    --mount type=bind,source=/etc/letsencrypt,destination=/etc/letsencrypt hamburml/docker-flow-letsencrypt:latest
```

You should always start the service on the same docker host. You must not scale it to two, this wouldn't make any sense!
The certificates are only renewed when they are 60 days old or older.

Important: DOMAIN_COUNT needs to be the number of Domains you want certificates generated. We need to obey lets encrypts rate limits! https://letsencrypt.org/docs/rate-limits/

### Docker Logs

You can see the progress of the running service through the logs.

```
root@server # docker logs letsencrypt-companion....

Generate certificates for domains: ....
Use michael.hamburger@mail.de for certbot
run certbot for domain ...
IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at
   /etc/letsencrypt/live/domain1.com/fullchain.pem. Your cert will
   expire on 2017-04-07. To obtain a new or tweaked version of this
   certificate in the future, simply run certbot again. To
   non-interactively renew *all* of your certificates, run "certbot
   renew"
   ...
```

When you restart the service and the certificates can't be renewed

```
...
-------------------------------------------------------------------------------
Certificate not yet due for renewal; no action taken.
-------------------------------------------------------------------------------
...
```

## Feedback

Thanks for using docker-flow-letsencrypt. If you have problems or some ideas how this can be made better feel free to create a new issue. Thanks to Viktor Farcic for his help and docker flow :)
