#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
else
  echo '.env file not found. Please create it with the necessary environment variables.'
  exit 1
fi

# Ensure DOMAIN variable is set
if [ -z "$DOMAIN" ]; then
  echo "DOMAIN variable is not set in the .env file."
  exit 1
fi

# Replace placeholder in nginx template
sed "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/nginx.conf.template > nginx/nginx.conf

echo "nginx.conf updated with domain $DOMAIN"
