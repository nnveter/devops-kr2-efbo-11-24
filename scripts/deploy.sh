#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
unset REDIS_PASSWORD
if [[ ! -f .env ]]; then
  (umask 077; printf 'REDIS_PASSWORD=%s\n' "$(openssl rand -hex 24)" > .env)
fi
chmod 600 .env
docker compose up -d --build --wait
if [[ ! -f /etc/ssl/certs/kr2.crt ]]; then
  sudo openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout /etc/ssl/private/kr2.key -out /etc/ssl/certs/kr2.crt \
    -subj '/CN=stats.devops.local' -addext 'subjectAltName=DNS:stats.devops.local'
fi
sudo chmod 600 /etc/ssl/private/kr2.key
sudo chown root:root /etc/ssl/private/kr2.key
sudo install -m 644 nginx/kr2 /etc/nginx/sites-available/kr2
sudo ln -sfn /etc/nginx/sites-available/kr2 /etc/nginx/sites-enabled/kr2
sudo nginx -t
sudo systemctl reload nginx
docker compose ps
