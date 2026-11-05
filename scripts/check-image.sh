#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker build --progress=plain -t kr2-app:1.0 .
docker run --rm kr2-app:1.0 id
docker inspect -f '{{json .Config.Cmd}}' kr2-app:1.0
docker run -d --rm --name kr2-test -p 127.0.0.1:8003:8003 kr2-app:1.0
trap 'docker stop kr2-test >/dev/null 2>&1 || true' EXIT
for attempt in {1..30}; do
  if curl -fsS http://127.0.0.1:8003/health; then break; fi
  sleep 1
done
curl -fsS http://127.0.0.1:8003/health
time docker stop kr2-test
trap - EXIT
docker image ls kr2-app
