#!/bin/bash -eu

check_basedir_exists() {
  if [[ -d "${_BRED_BASEDIR}" ]]; then
    echo "bred directory already exists" >&2
    exit 1
  else
    mkdir "${_BRED_BASEDIR}/" >&2
  fi
}
  
setup_dirs() {
  mkdir "${_BRED_BASEDIR}/jm"
  mkdir "${_BRED_BASEDIR}/fs"
  mkdir "${_BRED_BASEDIR}/conf"
  truncate -s 0 "${_BRED_BASEDIR}/conf/brhosts"
  for _each in $(seq 1 4); do
    echo "localhost" >> "${_BRED_BASEDIR}/conf/brhosts"
  done
}

setup_symlinks() {
  for _each in bred xbred bred-core brutils/brp; do
    if [[ -f "${_DIR}/${_each}" ]] ; then
      local _dest="/usr/local/bin/$(basename ${_each})"
      if [[ -e "${_dest}" ]]; then
	sudo rm "${_dest}"
      fi
      sudo ln -s "$(readlink -e ${_each})" "${_dest}"
    else
      echo "A file ${_DIR}/${_each} was not found."
    fi
  done
}

_DIR=$(dirname $0)
_BRED_BASEDIR="${HOME}/.bred"

check_basedir_exists
setup_dirs
setup_symlinks

