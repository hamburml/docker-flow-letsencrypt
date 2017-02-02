#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "${GREEN}Docker Flow: Let's Encrypt started${NC}\n";
printf "We will use $CERTBOT_EMAIL for certificate registration with certbot. This e-mail is used by Let's Encrypt when you lose the account and want to get it back.\n";

staging='';
if [ "$CERTBOTMODE" ]; then
  printf "${RED}Staging environment of Let's Encrypt is activated! The generated certificates won't be trusted. But you will not reach Let’s Encrypt's rate limits.${NC}\n";
  staging='--staging';
fi

#we need to be careful and don't reach the rate limits of Let's Encrypt https://letsencrypt.org/docs/rate-limits/
#Let's Encrypt has a certificates per registered domain (20 per week) and a names per certificate (100 subdomains) limit
#so we should create ONE certificiates for a certain domain and add all their subdomains (max 100!)

COUNTER=$DOMAIN_COUNT;

until [  $COUNTER -lt 1 ]; do
  var="DOMAIN_$COUNTER";
  cur_domains=${!var};

  declare -a arr=$cur_domains;

  DOMAINDIRECTORY="/etc/letsencrypt/live/${arr[0]}";
  dom="";
  for i in "${arr[@]}"
  do
    dom="$dom -d $i"
  done

  printf "\nUse certbot-auto certonly --no-self-upgrade --standalone --non-interactive --expand --keep-until-expiring --agree-tos --preferred-challenges http-01 --rsa-key-size 4096 --redirect --hsts --staple-ocsp  $dom";

  certbot-auto certonly --no-self-upgrade --standalone --non-interactive --expand --keep-until-expiring --email $CERTBOT_EMAIL $dom --agree-tos $staging --preferred-challenges http-01 --rsa-key-size 4096 --redirect --hsts --staple-ocsp

  let COUNTER-=1
done

#prepare renewcron
if [ "$CERTBOTMODE" ]; then
  printf "SHELL=/bin/sh\nPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\nPROXY_INSTANCE_NAME=$PROXY_INSTANCE_NAME\nCERTBOTMODE=$CERTBOTMODE\n" > /etc/cron.d/renewcron 
else
  printf "SHELL=/bin/sh\nPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\nPROXY_INSTANCE_NAME=$PROXY_INSTANCE_NAME\n" > /etc/cron.d/renewcron 
fi


declare -a arr=$CERTBOT_CRON_RENEW;
for i in "${arr[@]}"
do
  printf "$i root /root/renewAndSendToProxy.sh > /var/log/dockeroutput.log\n" >> /etc/cron.d/renewcron
done

printf "\n" >> /etc/cron.d/renewcron

#run renewAndSendToProxy script which calls certbot renew (yeah, certbot will be run again but this isn't a problem. In fact this script is also run via cron and therefore we must call certbot renew), concatenates the certificates and sends them to the proxy
/root/renewAndSendToProxy.sh
