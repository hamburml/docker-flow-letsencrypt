#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#times we tried curl
TRIES=0

#maximum number of retries
MAXRETRIES=5

#timeout
TIMEOUT=5

printf "${GREEN}Hello! renewAndSendToProxy runs. Today is $(date)${NC}\n"

# send current certificates to proxy - after that do a certbot renew round (which could take some seconds) and send updated certificates to proxy (faster startup with https when old certificates are still valid)
for d in /etc/letsencrypt/live/*/ ; do
    #move to directory
    cd $d

    #get directory name (which is the name of the regular domain)
    folder=${PWD##*/}

    #concat certificates
    printf "old certificates for $folder will be send to proxy\n"
    cat cert.pem chain.pem privkey.pem > $folder.combined.pem

    #send to proxy, retry up to 5 times with a timeout of $TIMEOUT seconds

    #reset tries to 0
    TRIES=0
    exitcode=0
    until [ $TRIES -ge $MAXRETRIES ]
    do
      TRIES=$[$TRIES+1]
      curl --silent --show-error -i -XPUT \
           --data-binary @$folder.combined.pem \
           "$PROXY_ADDRESS:8080/v1/docker-flow-proxy/cert?certName=$folder.combined.pem&distribute=true" > /var/log/dockeroutput.log && break
      exitcode=$?
      if [ $TRIES -eq $MAXRETRIES ]; then
        printf "old certificate: ${RED}transmit failed after ${TRIES} attempts.${NC}\n"
      else
        printf "old certificate: ${RED}transmit failed, we try again in ${TIMEOUT} seconds.${NC}\n"
        sleep $TIMEOUT
      fi
    done

    if [ $exitcode -eq 0 ]; then
      printf "old certificates: proxy received $folder.combined.pem\n"
    fi
done


#full path is needed or it is not started when run as cron

#--no-bootstrap: prevent the certbot-auto script from installing OS-level dependencies
#--no-self-upgrade: revent the certbot-auto script from upgrading itself to newer released versions
/root/certbot-auto renew --no-bootstrap --no-self-upgrade > /var/log/dockeroutput.log

printf "Docker Flow: Proxy DNS-Name: ${GREEN}$PROXY_ADDRESS${NC}\n";

for d in /etc/letsencrypt/live/*/ ; do
    #move to directory
    cd $d

    #get directory name (which is the name of the regular domain)
    folder=${PWD##*/}
    printf "current folder name is: $folder\n"

    #concat certificates
    printf "concat certificates for $folder\n"
    cat cert.pem chain.pem privkey.pem > $folder.combined.pem
    printf "${GREEN}generated $folder.combined.pem${NC}\n"

    #send to proxy, retry up to 5 times with a timeout of $TIMEOUT seconds
    printf "${GREEN}transmit $folder.combined.pem to $PROXY_ADDRESS${NC}\n"

    #reset tries to 0
    TRIES=0

    exitcode=0
    until [ $TRIES -ge $MAXRETRIES ]
    do
      TRIES=$[$TRIES+1]
      curl --silent --show-error -i -XPUT \
           --data-binary @$folder.combined.pem \
           "$PROXY_ADDRESS:8080/v1/docker-flow-proxy/cert?certName=$folder.combined.pem&distribute=true" > /var/log/dockeroutput.log && break
      exitcode=$?

      if [ $TRIES -eq $MAXRETRIES ]; then
        printf "${RED}transmit failed after ${TRIES} attempts.${NC}\n"
      else
        printf "${RED}transmit failed, we try again in ${TIMEOUT} seconds.${NC}\n"
        sleep $TIMEOUT
      fi
    done

    if [ $exitcode -eq 0 ]; then
      printf "proxy received $folder.combined.pem\n"
    fi

done

printf "${RED}/etc/letsencrypt will be backed up as backup-date-time.tar.gz. It's important to know that some files are symbolic links (inside this backup) and they need to be untared correctly.${NC}\n"
cd /etc/letsencrypt
mkdir -p backup
if [ "$CERTBOTMODE" ]; then
  tar -cpz --exclude='./backup' -f ./backup/backup-`date +%Y%m%d_%H%M%S_%Z`-$CERTBOTMODE.tar.gz .
else
  tar -cpz --exclude='./backup' -f ./backup/backup-`date +%Y%m%d_%H%M%S_%Z`-live.tar.gz .
fi


printf "${RED}Backup created, if you like download the /etc/letsencrypt/backup folder and store it on a safe place!${NC}\n\n"

printf "${GREEN}Thanks for using Docker Flow: Let's Encrypt and have a nice day!${NC}\n\n"
