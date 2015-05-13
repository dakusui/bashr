msg() {
  echo "$@" >&2
}

__read_func() {
  # 0 function reduce test_reduce2(a,b) inline:grep a b c
  # 1 reduce
  # 2 test_reduce2
  # 3 a,b
  # 4 inline:grep a b c
  # 5 
  # 6 
  # 7 inline:grep a b c
  
  # 0 function local main(sh) infline:<<EOF
  # 1 local
  # 2 main
  # 3 sh
  # 4 infline:<<EOF
  # 5 <<EOF
  # 6 EOF
  # 7
  local _line=$1
  local _type _funcname _args _jobdef
  local _regex=
  _regex="^function[[:space:]]+(map|reduce|local|pipe)[[:space:]]+([A-Za-z_][A-Za-z_0-9]*)[[:space:]]*"
  _regex="${_regex}\(([^\)]*)\)[[:space:]]*"
  _regex="${_regex}([a-z]+\:)(<<([A-Za-z0-9_]+)|(.+))$"
  if [[ "${_line}" =~ $_regex ]]; then
    _type="${BASH_REMATCH[1]}"
    _funcname="${BASH_REMATCH[2]}"
    _args="${BASH_REMATCH[3]}"
    _jobdef="${BASH_REMATCH[4]}"
    _endmark="${BASH_REMATCH[6]}"
    local _c=0
    for _i in "${BASH_REMATCH[@]}"; do
      echo "${_c} ${_i}"
      _c=$((${_c} + 1))
    done

    if [[ "${_endmark}" != "" ]]; then
      local _tail="${BASH_REMATCH[5]}"
      local _next
      while read -r _next ; do
	if [[ "${_next}" == "${_endmark}" ]]; then
	  break
	fi
    	_jobdef=$(printf '%s%s\n ' "${_jobdef}" "${_next}")
      done
    fi
  else
    echo "line didn't match"
    return 1
  fi
  echo "type='${_type}' funcname='${_funcname}' args='${_args}' jobdef='${_jobdef}'"
}
read_func() {
  # 0 function reduce test_reduce2(a,b) inline:grep a b c
  # 1 reduce
  # 2 test_reduce2
  # 3 a,b
  # 4 inline:grep a b c
  # 5 
  # 6 
  # 7 inline:grep a b c
  
  # 0 function local main(sh) infline:<<EOF
  # 1 local
  # 2 main
  # 3 sh
  # 4 infline:<<EOF
  # 5 <<EOF
  # 6 EOF
  # 7
  local _line=$1
  local _typename _funcname _args _jobdef
  local _regex=
  _regex="^function[[:space:]]+(map|reduce|local|pipe)[[:space:]]+([A-Za-z_][A-Za-z_0-9]*)[[:space:]]*"
  _regex="${_regex}\(([^\)]*)\)[[:space:]]*"
  _regex="${_regex}([a-z]+\:)(<<([A-Za-z0-9_]+)|(.+))$"
  if [[ "${_line}" =~ $_regex ]]; then
    _typename="${BASH_REMATCH[1]}"
    _funcname="${BASH_REMATCH[2]}"
    _args="${BASH_REMATCH[3]}"
    _jobdef="${BASH_REMATCH[4]}"
    _endmark="${BASH_REMATCH[6]}"
    local _c=0
    for _i in "${BASH_REMATCH[@]}"; do
      echo "${_c} ${_i}"
      _c=$((${_c} + 1))
    done

    if [[ "${_endmark}" != "" ]]; then
      local _tail="${BASH_REMATCH[5]}"
      local _next
      while read -r _next ; do
	if [[ "${_next}" == "${_endmark}" ]]; then
	  break
	fi
    	_jobdef=$(printf '%s%s\n ' "${_jobdef}" "${_next}")
      done
    fi
  else
    echo "line didn't match"
    return 1
  fi
  local _type=
  case "$_typename" in
    "map")    _type="M";;
    "reduce") _type="R";;
    "local")  _type="L";;
    *) msg "Unsupported function type '${_typename}'." && exit 1;;
  esac
  IFS="," read -r _interpreter _key _sinks <<< "${_args}"
  # _id _type _sinks _key _interpreter _task
  local _debug="*"
  echo "${_debug}${_funcname}"
  echo "${_debug}${_type}"
  echo "${_debug}${_sinks}"
  echo "${_debug}${_key}"
  echo "${_debug}${_interpreter}"
  echo "${_debug}${_jobdef}"
}


_line=
read -r _line
read_func "${_line}"


