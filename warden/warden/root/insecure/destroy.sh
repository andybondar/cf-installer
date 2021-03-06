#!/bin/bash

[ -n "$DEBUG" ] && set -o xtrace
set -o nounset
set -o errexit
shopt -s nullglob

cd $(dirname "$0")

if [ -z "${1}" ]; then
  echo "Usage: ${0} <instance_path>"
  exit 1
fi

target=${1}

if [ -d "${target}" ]; then
  if [ -f "${target}/stop.sh" ]; then
    ${target}/stop.sh
  fi

  rm -rf ${target}
fi
