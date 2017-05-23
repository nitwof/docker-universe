#!/bin/sh
vagrant ssh node3 -c "/vagrant/docker-universe.sh leave"
vagrant ssh node2 -c "/vagrant/docker-universe.sh leave"
vagrant ssh node1 -c "/vagrant/docker-universe.sh leave"
docker-compose down
