#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "${GREEN}Generate certificates for domains: ${NC}\n";
printf "Use $CERTBOTEMAIL for certbot\n";

staging='';
if [ "$CERTBOTMODE" ]; then
  printf "${RED}Use staging environment of letsencrypt!${NC}";
  staging='--staging';
fi

#we need to be careful and don't reach the rate limits of letsencrypt https://letsencrypt.org/docs/rate-limits/
#letsencrypt has a certificates per registered domain (20 per week) and a names per certificate (100 subdomains) limit
#so we should create ONE certificiates for a certain domain and add all their subdomains (max 100!)
#when the certain domain has more than 100 subdomains we create a second certificate for that certain domain!

COUNTER=$DOMAIN_COUNT;

until [  $COUNTER -lt 1 ]; do
  var="DOMAIN_$COUNTER";
  cur_domains=${!var};

  declare -a arr=$cur_domains;
  #printf "as array ${arr[1]}\n";

  DOMAINDIRECTORY="/etc/letsencrypt/live/${arr[0]}";
  dom="";
  for i in "${arr[@]}"
  do
    dom="$dom -d $i"
  done

  certbot certonly --standalone --non-interactive --expand --keep-until-expiring --email $CERTBOTEMAIL $dom --agree-tos $staging --standalone-supported-challenges http-01

  #concat certificates, use $DOMAINDIRECTORY and registered domain name (first domain agreement)
  printf "combine cert.pem chainpem and privkey.pem to $dom.combined.pem\n"
  cat $DOMAINDIRECTORY/cert.pem $DOMAINDIRECTORY/chain.pem $DOMAINDIRECTORY/privkey.pem > $DOMAINDIRECTORY/${arr[0]}.combined.pem
  printf "${GREEN}send ${arr[0]}.combined.pem to docker flow: proxy${NC}\n\n"

  #send certificate to proxy, use $PROXY_ADDRESS
  curl -i -XPUT \
         --data-binary @$DOMAINDIRECTORY/${arr[0]}.combined.pem \
         "$PROXY_ADDRESS:8080/v1/docker-flow-proxy/cert?certName=${arr[0]}.combined.pem&distribute=true"

  let COUNTER-=1
done
printf "Certificates generated and send to proxy! Cron should be started now which runs this script daily. Have fun using Docker Flow: Letsencrypt!";
/usr/bin/supervisord
