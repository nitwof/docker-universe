#!/bin/sh

TMP_DIR=${VLCP_TMP_DIR:-"/tmp"}
DOCKER_DIR=${VLCP_DOCKER_DIR:-"/var/lib/docker"}

function pack {
  volume_name=$1
  tar -cjf $TMP_DIR/$volume_name.tar.bz2 -C $DOCKER_DIR/volumes/$volume_name .
}

function unpack {
  volume_name=$1
  host=$2
  if [ -z "$host" ]
  then
    rm -rf $DOCKER_DIR/volumes/$volume_name
    mkdir $DOCKER_DIR/volumes/$volume_name
    tar -xjf $TMP_DIR/$volume_name.tar.bz2 -C $DOCKER_DIR/volumes/$volume_name
  else
    ssh -C $host "rm -rf $DOCKER_DIR/volumes/$volume_name"
    ssh -C $host "mkdir $DOCKER_DIR/volumes/$volume_name"
    ssh -C $host "tar -xjf $TMP_DIR/$volume_name.tar.bz2 -C $DOCKER_DIR/volumes/$volume_name"
  fi
}

function cleanup {
  volume_name=$1
  host=$2
  if [ -z "$host" ]
  then
    rm -f $TMP_DIR/$volume_name.tar.bz2
  else
    ssh -C $host "rm -f $TMP_DIR/$volume_name.tar.bz2"
  fi
}

function copy {
  volume_name=$1
  host=$2
  scp $TMP_DIR/$volume_name.tar.bz2 $host:$TMP_DIR
}

volume_name=$1
host=$2
pack $volume_name
copy $volume_name $host
unpack $volume_name $host
cleanup $volume_name
cleanup $volume_name $host
