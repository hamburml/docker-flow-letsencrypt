FROM ubuntu:16.10

RUN apt-get update && apt-get -y install cron && apt-get -y install certbot && apt-get install -y supervisor && apt-get install -y curl  && apt-get install -y nano

# Add supervisord.conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf 

# Add certbot
ADD certbot /root/certbot
RUN chmod u+x /root/certbot

# Add crontab file in the cron directory
ADD flow-proxy-certbot /etc/cron.daily/flow-proxy-certbot

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.daily/flow-proxy-certbot

# Create the log file to be able to run tail
RUN touch /var/log/flow-proxy-certbot.log

# Run the command on container startup
CMD /usr/bin/supervisord && tail -f /var/log/flow-proxy-certbot.log #printenv && cron 

EXPOSE 80

EXPOSE 443
