FROM ubuntu:16.10

RUN apt-get update && apt-get -y install cron && apt-get -y install certbot && apt-get install -y supervisor && apt-get install -y curl  && apt-get install -y nano

# Add supervisord.conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf 

# Add certbot
ADD certbot.sh /root/certbot.sh
RUN chmod u+x /root/certbot.sh

# Add crontab file in the cron directory
RUN ln -s /root/certbot.sh /etc/cron.daily/certbot.sh

# Run the command on container startup
CMD /root/certbot.sh && /usr/bin/supervisord

EXPOSE 80

EXPOSE 443
