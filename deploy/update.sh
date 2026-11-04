#!/bin/sh
# Keeps the server on the latest published image. Run every minute by deploy/systemd/camping-update.timer.
#
#   1. Checks ghcr.io/thykel/camping-guide:latest. If it's what's running, stops there (a registry lookup).
#   2. Otherwise pulls the repo, so the compose file and this script match the new image,
#      then restarts api (migrations run on start) -> health check -> roll back on failure.
#
# Pin a version by setting CAMPING_TAG=<commit sha> in .env; auto-update then does nothing.
set -eu

script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$script")/.."

log() { echo "[camping-update] $*"; }

# One run at a time
exec 9>"${TMPDIR:-/tmp}/camping-update.lock"
flock -n 9 || exit 0

env_value() { sed -n "s/^$1=//p" .env 2>/dev/null | tail -1; }
IMAGE=ghcr.io/thykel/camping-guide
tag=$(env_value CAMPING_TAG)
if [ -n "$tag" ] && [ "$tag" != "latest" ]; then
  exit 0
fi
failed_file=.update-failed   # image that failed its health check; skipped until a newer one is published

# 1. App image
if ! out=$(docker compose pull -q api 2>&1); then
  log "error: couldn't pull $IMAGE:latest: $out"
  exit 1
fi
latest=$(docker image inspect -f '{{.Id}}' "$IMAGE:latest")
container=$(docker compose ps -q api)
running=$( [ -n "$container" ] && docker inspect -f '{{.Image}}' "$container" || echo none)
[ "$latest" = "$running" ] && exit 0
[ -f "$failed_file" ] && [ "$(cat "$failed_file")" = "$latest" ] && exit 0

# 2. Deploy files. Every push to main publishes an image, so compose and script changes arrive with one.
before=$(git rev-parse HEAD)
if git pull --ff-only -q 2>/dev/null; then
  if [ "$(git rev-parse HEAD)" != "$before" ]; then
    log "repo updated to $(git rev-parse --short HEAD)"
    exec "$script"   # carry on with the updated script
  fi
else
  log "warning: git pull failed, continuing with the current checkout"
fi

short() { if [ "$1" = none ]; then echo "nothing"; else echo "$1" | cut -c8-19; fi; }
log "new image $(short "$latest"), was running $(short "$running")"

[ "$running" != none ] && docker tag "$running" "$IMAGE:previous"

docker compose up -d api

healthy() {
  i=0
  while [ $i -lt 60 ]; do      # db:prepare runs first: allow 2 minutes
    curl -fs -o /dev/null "http://127.0.0.1/up" 2>/dev/null && return 0
    i=$((i + 1)); sleep 2
  done
  return 1
}

if healthy; then
  log "updated, app is healthy"
  rm -f "$failed_file"
  docker image prune -f >/dev/null
else
  log "error: app didn't come up healthy, rolling back (this image is skipped until a newer one is published)"
  echo "$latest" > "$failed_file"
  if [ "$running" != none ]; then
    docker tag "$IMAGE:previous" "$IMAGE:latest"
    docker compose up -d api
    if healthy; then
      log "rolled back"
    else
      log "error: rollback isn't healthy either, check: docker compose logs api"
    fi
  fi
  exit 1
fi
