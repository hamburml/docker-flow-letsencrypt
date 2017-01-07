#!/bin/sh

echo "Generate certificates for domains:" $DOMAIN;
echo "Use" $CERTBOTEMAIL  "for certbot";

#split domains and call certbot certonly for every domain
IFS=',';
staging='';
if [ "CERTBOTMODE" ]; then
  staging='--staging';
fi
for i in $DOMAIN;
   do
   # check if certificate already exists (can happen when this is the second time the service is run, check if folder exists)
   # if folder exists, make certbot renew, if folder doesn't exist, make certbot certonly
      DOMAINDIRECTORY="/etc/letsencrypt/live/$i";
      dom=$i
      
      printf "run certbot for domain $dom \n";
      certbot certonly --standalone --non-interactive --keep-until-expiring --email $CERTBOTEMAIL -d $dom --agree-tos $staging --standalone-supported-challenges http-01
      printf "certificate created\n\n"

      #concat the certificate
      printf "combine cert.pem chainpem and privkey.pem to $dom.combined.pem\n"
      cat $DOMAINDIRECTORY/cert.pem $DOMAINDIRECTORY/chain.pem $DOMAINDIRECTORY/privkey.pem > $DOMAINDIRECTORY/$dom.combined.pem
      printf "send $dom.combined.pem to docker flow: proxy\n\n"

      curl -i -XPUT \
         --data-binary @$DOMAINDIRECTORY/$dom.combined.pem \
         "$PROXY_ADDRESS:8080/v1/docker-flow-proxy/cert?certName=$dom.combined.pem&distribute=true"

   done
