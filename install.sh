#!/bin/bash -eu

_DIR=$(dirname $0)
_BRED_BASEDIR="${HOME}/.bred"

if [[ -d "${_BRED_BASEDIR}" ]]; then
  echo "bred directory already exists" >&2
  exit 1
else
  mkdir "${_BRED_BASEDIR}/" >&2
fi

mkdir "${_BRED_BASEDIR}/jm"
mkdir "${_BRED_BASEDIR}/fs"
mkdir "${_BRED_BASEDIR}/conf"
truncate -s 0 "${_BRED_BASEDIR}/conf/brhosts"
for _each in $(seq 1 4); do
  echo "localhost" >> "${_BRED_BASEDIR}/conf/brhosts"
done

for _each in bred xbred bred-core; do
  if [[ -f "${_DIR}/${_each}" ]] ; then
    echo sudo ln -s "$(readlink -e ${_each})" "/usr/local/bin/${_each}"
  else
    echo "A file ${_DIR}/${_each} was not found."
  fi
done
