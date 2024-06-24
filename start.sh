#!/bin/bash

vim .env
vim xray/etc/config.json
chmod +x ./update-nginx-conf.sh
./update-nginx-conf.sh
./init-letsencrypt.sh
docker compose down
docker compose up -d
docker compose ps
docker compose logs -f