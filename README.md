Docker Flow: Let's Encrypt
==================

* [Introduction](#introduction)
* [How does it work](#how-does-it-work)
* [Usage](#usage)
* [Feedback and Contribution](#feedback-and-contribution)

## Introduction

This project is compatible with Viktor Farcic's [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy) and [Docker Flow: Swarm Listener](https://github.com/vfarcic/docker-flow-swarm-listener).
It uses certbot-auto to create and renew ssl certificates from Let’s Encrypt for your domains and stores them inside /etc/letsencrypt thus it requires a persistant storage.
You can bind a folder from the host and use a constraint to make sure the companion service always runs on the same host or use storage plugins such as [rexray](https://github.com/codedellemc/rexray) to allow data to follow your container on other nodes.

The service setups a cron which runs by default two times a day (03:00 and 15:00 UTC) and calls [renewAndSendToProxy](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewAndSendToProxy.sh). You can overwrite these cron behavior with the correct environment variables. It runs certbot-auto renew and uploads the certificates to the running [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy) service.

You can find this project also on [Docker Hub](https://hub.docker.com/r/hamburml/docker-flow-letsencrypt/).

## How does it work

This docker image uses certbot-auto, curl and cron to create and renew your Let’s Encrypt certificates.
Through environment variables you set the domains certbot-auto should create certificates for, which e-mail is used by Let’s Encrypt when you lose the account and want to get it back, the cronjob starting times and the dns-name of [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy).

When the image starts, the [certbot.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/certbot.sh) script runs and creates/renews the certificates and creates /etc/cron.d/renewcron. The script also runs [renewAndSendToProxy.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewAndSendToProxy.sh) which combines the cert.pem, chain.pem and privkey.pem to a domainname.combined.pem file and uploads your cert via curl to your proxy.

[renewAndSendToProxy.sh](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/renewAndSendToProxy.sh) also calls certbot-auto renew because this script is run by default two times a day (03:00 and 15:00 UTC) via /etc/cron.d/renewcron. You can overwrite this behavior by changing CERTBOT_CRON_RENEW environment variable. This script also creates backups of the /etc/letsencrypt folder which are stored in /etc/letsencrypt/backup. Don't worry, the backup folder is excluded from the tar command.

As you can see the output is piped into /var/log/dockeroutput.log. This file is created in the [Dockerfile](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/Dockerfile) and just redirects directly to the docker logs output. The logs are also colorized so that you are able to find the important information without hesitation.

If you only want to test this image you should add ```-e CERTBOTMODE="staging"``` when creating the service to use the staging mode of Let’s Encrypt. Remember that the certificate is not trusted so you will get a warning inside your browser.

Certbot-auto is called with  ```--rsa-key-size 4096 --redirect --hsts --staple-ocsp``` for improved security.

## Usage

### [Build](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/build)
```
docker build -t hamburml/docker-flow-letsencrypt .
```

### [Run](https://github.com/hamburml/docker-flow-letsencrypt/blob/master/run)

Attention! If you use local storage, create the `/etc/letsencrypt` folder before you start the service.

```
docker service create --name letsencrypt-companion \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/.well-known/acme-challenge \
    --label com.df.port=80 \
    -e DOMAIN_1="('haembi.de' 'www.haembi.de' 'blog.haembi.de')"\
    -e DOMAIN_2="('michael-hamburger.de' 'www.michael-hamburger.de' 'blog.michael-hamburger.de')"\
    -e CERTBOT_EMAIL="your.mail@mail.de" \
    -e PROXY_ADDRESS="proxy" \
    -e CERTBOT_CRON_RENEW="('0 3 * * *' '0 15 * * *')"\
    --network proxy \
    --mount type=bind,source=/etc/letsencrypt,destination=/etc/letsencrypt \
    --constraint 'node.id==<nodeId>' \
    --replicas 1 hamburml/docker-flow-letsencrypt:latest
```

The `aclName` label is optional. However it helps the proxy to order the ACls and make sure that the companion rule is above other service rules since the rules are added sequentially so ACME verification works.

You may also use a stack file to deploy the letsencrypt companion. The content of the [docker-compose-stack.yml](docker-compose-stack.yml) file is:

```
version: "3"

services:

  # Let's Encrypt Companion
  letsencrypt-companion:
    image: hamburml/docker-flow-letsencrypt:latest
    networks:
      - proxy
    environment:
      - DOMAIN_1=('haembi.de' 'www.haembi.de' 'blog.haembi.de')
      - DOMAIN_2=('michael-hamburger.de' 'www.michael-hamburger.de' 'blog.michael-hamburger.de')
      - CERTBOT_EMAIL=your.mail@mail.de
      - PROXY_ADDRESS=proxy
      - CERTBOT_CRON_RENEW=('0 3 * * *' '0 15 * * *')
    volumes:
          - /etc/letsencrypt:/etc/letsencrypt
    deploy:
      labels:
        - com.df.servicePath=/.well-known/acme-challenge
        - com.df.notify=true
        - com.df.distribute=true
        - com.df.port=80
      placement:
        constraints: [node.id == <nodeId>]
      replicas: 1

networks:
  proxy:
    external: true
```

As a full stack example with Viktor's proxy and listener, check the [docker-compose-full-stack.yml](docker-compose-full-stack.yml) file.

You should always start the service on the same docker host. You achieve this by setting <nodeId> to the id of the docker host on which the service should run. The nodeId can be get via ```docker node ls```. 
You must not scale the service to two, this wouldn't make any sense! Only one instance of this companion should run.
The certificates are only renewed when they are 60 days old or older. This is standard certbot-auto behavior. But the certificates will be renewed when you add subdomains to the domain-list! If you want to change the number of times certbot-auto renew and the publish script is called you need to change CERTBOT_CRON_RENEW. The syntax is described [here](http://www.adminschoice.com/crontab-quick-reference). 

Important: The first domain must always be the domain without any subdomains. That makes the folder-structure regular.

We need to obey Let’s Encrypt’s rate limits! https://letsencrypt.org/docs/rate-limits/

### Docker Logs

You can see the progress of the running service through the logs.

```
root@server # docker logs letsencrypt-companion... -f

Docker Flow: Let's Encrypt started
We will use your.email@mail.de for certificate registration with certbot. This e-mail is used by Let's Encrypt when you lose the account and want to get it back.

Use certbot --standalone --non-interactive --expand --keep-until-expiring --agree-tos --standalone-supported-challenges http-01 --rsa-key-size 4096 --redirect --hsts --staple-ocsp   -d domain1.de -d www.domain1.de -d subdomain1.domain1.de 
-------------------------------------------------------------------------------
Certificate not yet due for renewal; no action taken.
-------------------------------------------------------------------------------
(removed some entries...)
Docker Flow: Proxy DNS-Name: proxy
current folder name is: domain1.de
concat certificates for domain1.de
generated domain1.de.combined.pem
transmit domain1.de.combined.pem to proxy
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  7114    0     0  100  7114      0   108k --:--:-- --:--:-- --:--:--  108k
HTTP/1.1 100 Continue

HTTP/1.1 200 OK
Date: Tue, 10 Jan 2017 18:54:43 GMT
Content-Length: 0
Content-Type: text/plain; charset=utf-8

proxy received domain1.de.combined.pem
(removed some entries...)
Thanks for using Docker Flow: Let's Encrypt and have a nice day!

Starting supervisord (which starts and monitors cron)
(removed some entries...)
```

When you restart the service and the certificates can't be renewed the logs will show this also.

```
...
-------------------------------------------------------------------------------
Certificate not yet due for renewal; no action taken.
-------------------------------------------------------------------------------
...
```

## Feedback

Thanks for using docker-flow-letsencrypt. If you have problems or some ideas how this can be made better feel free to create a new issue. Thanks to Viktor Farcic for his help and docker flow :)

<a href='https://ko-fi.com/A130K9R' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://az743702.vo.msecnd.net/cdn/kofi2.png?v=f' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a> 
