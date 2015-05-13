#!/bin/dash

read_vars_with_heredoc() {
  echo $@
  echo $#
  local _size=$#
  local _cur=
  read -r _cur
  if [[ "${_cur}" == "*<<:BATYR" ]] ; then
    :
  fi
}

read_line() {
  local _cur
  read -r _cur
}

read_arr a b c


