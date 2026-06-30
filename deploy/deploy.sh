#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f ../backend/service-account.json ]; then
  echo "ERROR: ../backend/service-account.json topilmadi. Avval uni serverga yuklang."
  exit 1
fi

docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps

echo
echo "Health check:"
sleep 3
curl -s http://127.0.0.1:8090/health || true
echo
