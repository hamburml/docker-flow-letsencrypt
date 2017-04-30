#use 16.04 lts, install certbot-auto to get newest certbot version
FROM ubuntu:16.04

#set default env variables
ENV CERTBOT_EMAIL="" \
    PROXY_ADDRESS="proxy" \
    CERTBOT_CRON_RENEW="('0 3 * * *' '0 15* * *')" \
    PATH="$PATH:/root"

# http://stackoverflow.com/questions/33548530/envsubst-command-getting-stuck-in-a-container
RUN apt-get update && apt-get -y install cron && apt-get install -y supervisor && apt-get install -y wget && apt-get install -y curl

# install certbot-auto
RUN cd /root && wget https://dl.eff.org/certbot-auto
RUN chmod a+x /root/certbot-auto
RUN ./root/certbot-auto --version --non-interactive
RUN PATH=$PATH:/root

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

ADD servicestart /root/servicestart
RUN chmod u+x /root/servicestart

# Run the command on container startup
CMD ["bin/bash", "/root/servicestart"]

EXPOSE 80
