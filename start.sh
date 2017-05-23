#!/bin/sh
docker-compose up -d registry
docker build -t localhost:5000/group-supervisor -f du-group-supervisor/Dockerfile du-group-supervisor
docker push localhost:5000/group-supervisor

vagrant ssh node1 -c "/vagrant/docker-universe.sh start"
sleep 2
vagrant ssh node2 -c "/vagrant/docker-universe.sh join 192.168.33.11"
sleep 2
vagrant ssh node3 -c "/vagrant/docker-universe.sh join 192.168.33.11"
