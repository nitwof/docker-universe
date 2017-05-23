#!/bin/bash

GSUP_IMAGE="192.168.33.1:5000/group-supervisor"

function create_group {
  join=$1
  selfip=$(hostname -I | tr " " "\n" | grep 192.168.33 | head -n 1)
  docker swarm init --advertise-addr $selfip
  docker pull $GSUP_IMAGE
  docker network create --driver overlay groupnet
  docker service create --network groupnet --name group_storage redis
  join_env=$([ "$join" != "" ] && echo "--env JOIN=$join" || echo "")
  docker service create --network groupnet \
                        --publish 10000:10000 \
                        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
                        --env STORAGE_URL="redis://group_storage:6379/0" \
                        --env HOSTNAME=$selfip \
                        $join_env \
                        --name group_supervisor $GSUP_IMAGE
}

function start {
  create_group
}

function join {
  host=$1
  group=$(curl -s "http://$host:10000/nodes/group" | jq -r ".group")
  echo "GROUP: $group"
  if [ "$group" != "null" ]; then
    host=$(echo "$group" | jq -r ".supervisor")
    echo "NEW HOST: $host"
    token=$(curl -s "http://$host:10000/nodes/swarm_token" | jq -r ".token")
    echo "TOKEN: $token"
    docker swarm join --token $token "$host:2377"
  else
    echo "CREATE GROUP"
    create_group "$host"
  fi
}

function leave {
  docker swarm leave -f
}

function print_usage {
  echo "Usage: docker-universe.sh COMMAND"
  echo "Commands:"
  echo "  start - Starts new universe from current node"
  echo "  join HOST - Joins current node to universe though HOST"
}

case "$1" in
  start)
    start
    ;;
  join)
    join $2
    ;;
  leave)
    leave
    ;;
  *)
    print_usage
    ;;
esac
