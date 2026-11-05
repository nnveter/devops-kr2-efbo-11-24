#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
backup=$(mktemp)
cp docker-compose.yml "$backup"
restore() {
  cp "$backup" docker-compose.yml
  docker compose up -d --wait
  rm -f "$backup"
}
trap restore EXIT
sed -i 's/127.0.0.1:8003:8003/0.0.0.0:8003:8003/' docker-compose.yml
docker compose up -d --wait
set +e
~/devops-course-2026/scripts/audit.sh
rc=$?
set -e
echo "Negative audit exit code: $rc"
test "$rc" -eq 1
restore
trap - EXIT
~/devops-course-2026/scripts/audit.sh
