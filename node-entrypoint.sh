#!/bin/sh
/usr/local/bin/dockerd 2>/dev/null &
/usr/local/bin/docker-entrypoint.sh "$@"
