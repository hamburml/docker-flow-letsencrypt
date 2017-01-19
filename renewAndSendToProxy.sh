#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "${GREEN}Hello! renewAndSendToProxy runs. Today is $(date)${NC}\n"

#full path is needed or it is not started when run as cron
/root/certbot-auto renew > /var/log/dockeroutput.log

printf "Docker Flow: Proxy DNS-Name: ${GREEN}$PROXY_INSTANCE_NAME${NC}\n";

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

    #send to proxy
    printf "${GREEN}transmit $folder.combined.pem to $PROXY_INSTANCE_NAME${NC}\n"

    curl -i -XPUT \
         --data-binary @$folder.combined.pem \
         "$PROXY_INSTANCE_NAME:8080/v1/docker-flow-proxy/cert?certName=$folder.combined.pem&distribute=true" > /var/log/dockeroutput.log

    printf "proxy received $folder.combined.pem\n"

done

printf "${RED}/etc/letsencrypt will be backed up as backup-date-time.tar.gz. It's important to know that some files are symbolic links (inside this backup) and they need to be untared correctly.${NC}\n"
cd /etc/letsencrypt
mkdir -p backup
tar -cpz --exclude='./backup' -f ./backup/backup-`date +%Y%m%d_%H%M%S_%Z`-$CERTBOTMODE.tar.gz .
printf "${RED}Backup created, if you like download the /etc/letsencrypt/backup folder and store it on a safe place!${NC}\n\n"

printf "${GREEN}Thanks for using Docker Flow: Let's Encrypt and have a nice day!${NC}\n\n"
