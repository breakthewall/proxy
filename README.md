Fully dockerized web proxy based on NGINX and with letsencrypt certificates management.

This code is inspired by https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71. I changed certbot folders on host by Docker data volumes and fully dockerized the script.

## Create or Renew certificate
```$ bash init-letsencrypt.sh```

## Run proxy
```$ docker-compose up -d nginx```

## Add a new /suffix
Add entries in ```config/conf.d/galaxy.conf```
Add network in ```docker-compose.yml in two places```
