#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

IFS=$'\r\n' GLOBIGNORE='*' command eval  'domains=($(cat domains.txt))'
rsa_key_size=4096
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits


docker-compose run --rm init-letsencrypt sh -c "\
  if [ ! -e \"/etc/letsencrypt/options-ssl-nginx.conf\" ]; then \
    echo \"### Downloading recommended TLS parameters ...\" &&\
    wget -q https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf -O /etc/letsencrypt/options-ssl-nginx.conf; \
  fi"

docker-compose run --rm --entrypoint "" certbot sh -c "\
  if [ ! -e \"/etc/letsencrypt/ssl-dhparams.pem\" ]; then \
     openssl dhparam -out /etc/letsencrypt/ssl-dhparam.pem 4096 ; \
     chmod 600 /etc/letsencrypt/ssl-dhparam.pem ; \
  echo ;\
  fi"

#for domain in "${domains[@]}"; do
  #  echo $CERT_PATH ;\
CERT_PATH=/etc/letsencrypt/live/$domain
docker-compose run --rm --entrypoint "" certbot sh -c "\
  echo \"### Creating dummy certificate for $domain ...\" ;\
  mkdir -p $CERT_PATH ;\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
    -keyout \"$CERT_PATH/privkey.pem\" \
    -out \"$CERT_PATH/fullchain.pem\" \
    -subj '/CN=localhost'"
echo
#done

echo "### Starting nginx ..."
docker-compose up --force-recreate -d nginx
echo

#for domain in "${domains[@]}"; do
echo "### Deleting dummy certificate for $domain ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domain && \
  rm -Rf /etc/letsencrypt/archive/$domain && \
  rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
echo

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

echo "### Requesting Let's Encrypt certificate for ${domains[@]} ..."
# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi
docker-compose run --rm --entrypoint "\
certbot certonly --webroot -w /var/www/certbot \
$staging_arg \
$email_arg \
-d $domain \
--rsa-key-size $rsa_key_size \
--agree-tos \
--force-renewal" certbot
echo
#done



echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
