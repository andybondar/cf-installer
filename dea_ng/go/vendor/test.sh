#!/bin/bash

go=$(readlink -nf bin/go)

for i in $(find src -name '*_test.go' | xargs -n1 dirname | uniq)
do
  pushd $i > /dev/null

  echo
  echo "$i:"

  $go test

  popd > /dev/null
done
