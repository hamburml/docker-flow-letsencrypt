FROM ubuntu:16.10
# http://stackoverflow.com/questions/33548530/envsubst-command-getting-stuck-in-a-container
RUN apt-get update && apt-get -y install cron && apt-get -y install certbot && apt-get install -y supervisor && apt-get install -y curl && apt-get install -y gettext-base 

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

# Run the command on container startup
CMD /root/certbot.sh > /var/log/dockeroutput.log && /usr/bin/supervisord

EXPOSE 80

