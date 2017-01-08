FROM ubuntu:16.10

RUN apt-get update && apt-get -y install cron && apt-get -y install certbot && apt-get install -y supervisor && apt-get install -y curl
# Add supervisord.conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf 

# Add certbot and make it executable
ADD certbot.sh /root/certbot.sh
RUN chmod u+x /root/certbot.sh

# Add symbolic link in cron.daily directory without ending (important!)
RUN ln -s /root/certbot.sh /etc/cron.hourly/certbot

# Run the command on container startup
CMD /root/certbot.sh

EXPOSE 80
