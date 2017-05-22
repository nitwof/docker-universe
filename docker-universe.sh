#!/bin/sh

GSUP_IMAGE="registry:5000/group-supervisor"

function create_group () {
  join=$1
  docker swarm init
  docker pull $GSUP_IMAGE
  docker service create --mode global --name group_storage redis
  join_env=$(test -z $1 && echo "--env JOIN=$1" || echo "")
  docker service create --mode global -p 10000 \
                        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
                        --env STORAGE_URL="redis://group_storage:6379/0" \
                        --env HOSTNAME=$(hostname) \
                        $join_env \
                        --name group_supervisor $GSUP_IMAGE
}

function start () {
  create_group 
}

function join () {
  host=$1
  group=$(curl -s "http://$host:10000/nodes/group" | jq -r ".group")
  if [ "$group" = "null" ]; then
    token=$(curl -s "http://$host:10000/nodes/swarm_token" | jq -r ".token")
    docker swarm join --token token "$host:2377"
  else
    create_group "$host:10000"
  fi
}

function print_usage () {
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
  *)
    print_usage
    ;;
esac
