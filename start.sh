#!/bin/sh
docker-compose up -d node
docker-compose exec node /data/docker-universe.sh start
