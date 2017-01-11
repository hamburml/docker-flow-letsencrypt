#use 16.10 ubuntu instead of lts because certbot is available in 16.10 (yakkety) in 16.04 (lts) it's not certbot, it's letsencrypt (and i don't know if they are perfectly the same)
FROM ubuntu:16.10 

#set default env variables
ENV DOMAIN_COUNT=0 \
    CERTBOT_EMAIL="" \
    PROXY_INSTANCE_NAME="proxy" \
    CERTBOT_CRON_RENEW="('0 3 * * *' '0 15* * *')"

# http://stackoverflow.com/questions/33548530/envsubst-command-getting-stuck-in-a-container
RUN apt-get update && apt-get -y install cron && apt-get -y install certbot && apt-get install -y supervisor && apt-get install -y curl
# Add supervisord.conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf 

# Add certbot and make it executable
ADD certbot.sh /root/certbot.sh
RUN chmod u+x /root/certbot.sh

ADD renewAndSendToProxy.sh /root/renewAndSendToProxy.sh
RUN chmod u+x /root/renewAndSendToProxy.sh

RUN ln -sf /proc/1/fd/1 /var/log/dockeroutput.log

# Add symbolic link in cron.daily directory without ending (important!)
ADD renewcron /etc/cron.d/renewcron 
RUN chmod u+x /etc/cron.d/renewcron 

# Add script which runs when the service starts
ADD servicestart /root/servicestart
RUN chmod u+x /root/servicestart

# Run the command on container startup
CMD ["bin/bash", "/root/servicestart"]

EXPOSE 80

