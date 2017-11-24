#!/bin/bash

service=$1
host=$2
port=$3
proxy_port=$4
cmd="
create /proxy 0\n
create /proxy/services 0\n
create /proxy/services/$service $service\n
create /proxy/services/$service/host $host\n
create /proxy/services/$service/port $port\n
create /proxy/services/$service/proxy_port $proxy_port\n
create /proxy/services/$service/maintenance false
"

docker-compose exec zookeeper bash -c "echo -e '$cmd' | ./bin/zkCli.sh"
