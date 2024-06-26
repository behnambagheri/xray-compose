#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
else
  echo '.env file not found. Please create it with the necessary environment variables.'
  exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker compose is not installed.' >&2
  exit 1
fi

if ! [[ -d certbot/config ]]; then
    mkdir -p certbot/config

fi

domains=($DOMAIN)
rsa_key_size=4096
data_path="./certbot"
email="$EMAIL" # Adding a valid address is strongly recommended
staging="$STAGING" # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path/conf/live/$domains" ]; then
  echo "Existing data found for $domains. Continue and replace existing certificate? (y/N) "
  read decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/nginx-options-ssl.conf > "$data_path/conf/options-ssl-nginx.conf"
  echo
fi

echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

echo "### Starting nginx ..."
docker compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $domains ..."
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo

# Create cloudflare credentials

echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > certbot/config/cloudflare.ini
chmod 600 certbot/config/cloudflare.ini

echo "### Requesting Let's Encrypt certificate for $domains ..."
# Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker compose run --rm --entrypoint "\
  certbot certonly \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --non-interactive \
    --force-renewal \
    --dns-cloudflare \
    --dns-cloudflare-propagation-seconds 30 \
    --dns-cloudflare-credentials /config/cloudflare.ini" certbot
echo

echo "### Reloading nginx ..."
docker compose restart nginx
