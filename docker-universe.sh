#!/bin/bash

function print_usage {
  echo "Usage: docker-universe.sh [OPTIONS] COMMAND"
  echo "Options:"
  echo "  -b BIND_ADDR - Bind address. Required"
  echo "  -g GSUP_IMAGE - URL to group supervisor image in Docker registry"
  echo "  -h - Prints this help"
  echo "Commands:"
  echo "  start - Starts new universe from current node"
  echo "  join HOST - Joins current node to universe though HOST"
}

gsup_image="localhost:5000/group-supervisor"
while getopts "b:g:h" option; do
  case "$option" in
    g) gsup_image=$OPTARG;;
    b) bind_addr=$OPTARG;;
    h) print_usage; exit;;
  esac
done
shift $((OPTIND - 1))

function create_group {
  join=$1
  docker swarm init --advertise-addr $bind_addr
  docker pull $gsup_image
  docker network create --driver overlay groupnet
  docker service create --network groupnet --name group_storage redis
  join_env=$([ "$join" != "" ] && echo "--env JOIN=$join" || echo "")
  docker service create --network groupnet \
                        --publish 10000:10000 \
                        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
                        --env STORAGE_URL="redis://group_storage:6379/0" \
                        --env HOSTNAME=$bind_addr \
                        $join_env \
                        --name group_supervisor $gsup_image
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

case "$1" in
  start)
    if [ -z "$bind_addr" ]; then
      echo "-b options requied"
      exit 1
    fi
    start
    ;;
  join)
    if [ -z "$bind_addr" ]; then
      echo "-b options requied"
      exit 1
    fi
    join $2
    ;;
  leave)
    leave
    ;;
  *)
    print_usage
    ;;
esac
