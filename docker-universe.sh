#!/bin/sh

# GSUP_IMAGE="registry:5000/group-supervisor"
GSUP_IMAGE="docker:stable"

function start () {
  docker swarm init
  docker pull $GSUP_IMAGE
  docker service create --mode global --name group_storage redis
  docker service create --mode global -p 10000 \
                        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
                        --env STORAGE_URL="redis://group_storage:6379/0" \
                        --env HOSTNAME=$(hostname) \
                        --name group_supervisor $GSUP_IMAGE
}

function join () {
  host=$1

}

case "$1" in
  start)
    start
    ;;
  join)
    join $2
    ;;
  *)
    ;;
esac
