#!/bin/sh
# network-online.target can fire before the network is usable, and the NFS
# server may still be booting, so retry mount -a until everything mounts.
for i in $(seq 1 60); do
    if /usr/bin/mount -a; then
        exec /usr/bin/docker restart plex
    fi
    sleep 5
done
echo "plex-boot-fix: mount -a still failing after 60 attempts, giving up" >&2
exit 1
