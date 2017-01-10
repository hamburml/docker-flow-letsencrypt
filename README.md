docker-flow-letsencrypt
==================

* [Introduction](#introduction)
* [How does it work](#how-does-it-work)
* [Usage](#usage)
* [Feedback and Contribution](#feedback-and-contribution)

## Introduction

This project is compatible with [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy) and [Docker Flow: Swarm Listener](https://github.com/vfarcic/docker-flow-swarm-listener).
It uses certbot to create and renew https certificates for your domains and stores the certificates inside /etc/letsencrypt on the running docker host (you should run the service always on the same host, use docker service constraints). The service setups a cron which runs two times a day and calls a script. The script runs certbot renew and uploads the certificates to [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy).

https://hub.docker.com/r/hamburml/docker-flow-letsencrypt/

## How does it work

This docker image uses certbot, curl and cron to create and renew your letsencrypt certificates.
Through environment variables you can set the domains certbot should create certificates, which e-mail should be used for certbot and the dns-name of [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy).

When the image starts, the [certbot.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/certbot.sh) script runs and creates/renews the certificates. The script also runs [renewAndSendToProxy.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewAndSendToProxy.sh) which calls certbot renew, combines the cert.pem, chain.pem and privkey.pem to a domainname.combined.pem file and uploads your cert to the proxy.

[renewAndSendToProxy.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewAndSendToProxy.sh) also calls certbot renew because this script is run two times a day via the [renewcron](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewcron).

As you can see the output is piped into /var/log/dockeroutput.log. This file is created in the [Dockerfile](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/Dockerfile) and just redirects directly to the docker logs output.

If you only want to test this image you should add ```-e CERTBOTMODE="staging"``` when creating the service to use the staging mode of letsencrypt. The certificate is not trusted so you will get a warning inside your browser.

## Usage

### [Build](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/build)
```
docker build -t hamburml/docker-flow-letsencrypt .
```

### [Run](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/run)

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
    --constraint 'node.id==<nodeId>' \
    --replicas 1 \
    --mount type=bind,source=/etc/letsencrypt,destination=/etc/letsencrypt hamburml/docker-flow-letsencrypt:latest
```

You should always start the service on the same docker host. You achieve this by setting <nodeId> to the id of the docker host on which the service should run. Use ```docker node ls```. 
You must not scale it to two, this wouldn't make any sense! Only one instance of this companion should run.
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
