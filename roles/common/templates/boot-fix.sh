#!/bin/sh
# network-online.target can fire before the network (or the NFS server) is
# actually reachable, so retry mount -a until all filesystems are mounted.
# Plex has restart: unless-stopped, so it likely already started against a
# stale/empty mount by the time this runs - restart it explicitly to pick up
# the now-correct data. docker compose up -d covers any other container that
# never started at all.
cd "{{ USER_PATH }}" || exit 1

for i in $(seq 1 60); do
    if /usr/bin/mount -a; then
        /usr/bin/docker compose up -d
        exec /usr/bin/docker compose restart plex
    fi
    sleep 5
done

echo "boot-fix: mount -a still failing after 60 attempts, giving up" >&2
exit 1
