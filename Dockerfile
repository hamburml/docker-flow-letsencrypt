#use 16.04 lts, install certbot-auto to get newest certbot version
FROM certbot/certbot:v0.14.2

#set default env variables
ENV DEBIAN_FRONTEND=noninteractive \
    CERTBOT_EMAIL="" \
    PROXY_ADDRESS="proxy" \
    CERTBOT_CRON_RENEW="('0 3 * * *' '0 15* * *')" \
    PATH="$PATH:/root"

# http://stackoverflow.com/questions/33548530/envsubst-command-getting-stuck-in-a-container
RUN apk add --no-cache bash \
    curl

# Run the command on container startup
ENTRYPOINT ["/bin/bash"]


EXPOSE 80
