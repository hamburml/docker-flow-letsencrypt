# Docker Flow: Let's Encrypt - Examples

The letsencrypt-companion creates your SSL certificates. Therefore you always need only one running! This companion creates all certificates for you.
You specify the domains via environment variables DOMAIN_1, DOMAIN_2, DOMAIN_3, ...

Attention! If you use local storage, create the `/etc/letsencrypt` folder before you start the service and set the correct nodeId constraint. You are free to backup the `/etc/letsencrypt` folder.
Remember that Let's Encrypt has some rate limits https://letsencrypt.org/docs/rate-limits/. You can only create 20 certificates for the registered domain. You are adviced to not unnecessarily recreate the certificates. Normally a Let's Encrypt signed certificate is valid for 90 days. After 30 days the certificate can be renewed.

```
docker service create --name letsencrypt-companion \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/.well-known/acme-challenge \
    --label com.df.port=80 \
    -e DOMAIN_1="('domain1.de' 'www.domain1.de' 'blog.domain1.de')"\
    -e DOMAIN_2="('domain2.de' 'www.domain2.de' 'blog.domain2.de')"\
    -e CERTBOT_EMAIL="your.mail@mail.de" \
    -e PROXY_ADDRESS="proxy" \
    -e CERTBOT_CRON_RENEW="('0 3 * * *' '0 15 * * *')"\
    --network proxy \
    --mount type=bind,source=/etc/letsencrypt,destination=/etc/letsencrypt \
    --constraint 'node.id==<nodeId>' \
    --replicas 1 hamburml/docker-flow-letsencrypt:latest
```

This companion tries to create two certificates for domain1.de and domain2.de. The subdomains are added as `Names per Certificate`. The certbot-client runs runs by default two times a day (03:00 and 15:00 UTC). The Docker Flow: proxy is named `proxy`. The CA uses CERTBOT_EMAIL to send notification emails when the certificate isn't renewed.

The certificates are stored inside /etc/letsencrypt. Docker Flow: Proxy also supports certificates stored into docker secrets. This companion doesn't support docker secrets for now, because when a secret is updated all running docker services, which have access to this specific secret, are restarted. A restart of Docker Flow: Proxy would mean that ALL services aren't reachable anymore.
