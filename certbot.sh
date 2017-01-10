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

  printf "create for domain with subdomains $dom\n";

  certbot certonly --standalone --non-interactive --expand --keep-until-expiring --email $CERTBOTEMAIL $dom --agree-tos $staging --standalone-supported-challenges http-01

  let COUNTER-=1
done

/root/renewAndSendToProxy.sh
