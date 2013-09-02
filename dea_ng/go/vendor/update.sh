#!/bin/bash

go=$(readlink -nf bin/go)

function revision() {
  pushd src > /dev/null

  repository=$1
  revision=

  while [ "$repository" != "." ] && [ -z "$revision" ]
  do
    if [ -d $repository/.hg ]
    then
      pushd $repository > /dev/null
      revision=$(hg id -i)
      popd > /dev/null
    fi

    if [ -d $repository/.bzr ]
    then
      pushd $repository > /dev/null
      revision=$(bzr revno .)
      popd > /dev/null
    fi

    if [ -d $repository/.git ]
    then
      pushd $repository > /dev/null
      revision=$(git rev-parse HEAD)
      popd > /dev/null
    fi

    repository=$(dirname $repository)
  done

  if [ -z "$revision" ]
  then
    revision="(unknown)"
  fi

  echo $revision

  popd > /dev/null
}

function update() {
  echo -n "Updating $1... "
  $go get -u -d $1

  echo $(revision $1) > src/$1.revision
  cat src/$1.revision
}

if [ -n "$1" ]
then
  update $1
else
  update launchpad.net/gocheck
  update launchpad.net/goyaml
  update code.google.com/p/go.net/ipv4
  update code.google.com/p/go.net/spdy
  update code.google.com/p/go.net/websocket
  update github.com/cloudfoundry/gosteno
  update github.com/cloudfoundry/gonats
fi
