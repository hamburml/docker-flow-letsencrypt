#!/bin/bash

echo "Hello! It's $(date)"

certbot renew > /var/log/dockeroutput.log

for d in /etc/letsencrypt/live/*/ ; do
    #move to directory
    cd $d
    #get directory name (which is the name of the regular domain)
    folder=${PWD##*/}
    echo "current folder name is: $folder"

    #concat certificates
    echo "concat certificates for $folder"
    cat cert.pem chain.pem privkey.pem > $folder.combined.pem
    echo "generated $folder.combined.pem"

    #send to proxy
    echo "send $folder.combined.pem to proxy"

    curl -i -XPUT \
         --data-binary @$folder.combined.pem \
         "proxy:8080/v1/docker-flow-proxy/cert?certName=$folder.combined.pem&distribute=true" > /var/log/dockeroutput.log

    echo "proxy received $folder.combined.pem"
    

done
echo "Bye!"
