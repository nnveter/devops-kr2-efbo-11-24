#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
unset REDIS_PASSWORD
docker compose ps
for i in 1 2 3; do curl -fsS http://127.0.0.1:8003/; done
docker compose top
docker run --rm --user root kr2-app:1.0 find / -xdev -name .env
docker compose exec -T app getent hosts redis
docker compose exec -T redis redis-cli ping
docker compose port app 8003
docker compose port redis 6379 || true
sudo ss -tlnp | grep -E ':(8003|6379)\b'
before=$(curl -fsS http://127.0.0.1:8003/ | sed 's/.*hits: //')
sleep 2
docker compose down
docker volume ls --filter name=redis_data
docker compose up -d --wait
after=$(curl -fsS --retry 10 --retry-connrefused --retry-delay 1 http://127.0.0.1:8003/ | sed 's/.*hits: //')
echo "Persistence: before=$before after=$after"
test "$after" -eq "$((before+1))"
diff <(sudo ufw status numbered) ~/ufw-before-kr2.txt
echo 'UFW unchanged'
sudo ls -l /etc/ssl/private/kr2.key .env
pw=$(sed -n 's/^REDIS_PASSWORD=//p' .env)
test -n "$pw"
if grep -rlF --exclude=.env -- "$pw" .; then
  echo 'FAIL: secret found outside .env'; exit 1
else
  rc=$?; test "$rc" -eq 1; echo 'Secret absent from other project files'
fi
unset pw
~/devops-course-2026/scripts/audit.sh
