debug() {
  if [ "${XBRED_DEBUG:-off}" == "on" ]; then
    echo "${prog}: DEBUG: ${1}" >&2
  fi
}

joinstr() { local IFS="$1"; shift; printf "$*"; }

####
# Reads a function (job) from a xbred file
read_xbred_func() {
  local _line=$1
  local _typename _funcname _args _scheme _jobdef
  local _regex=
  _regex="^function[[:space:]]+(map|reduce|local|pipe)[[:space:]]+([A-Za-z_][A-Za-z_0-9]*)[[:space:]]*"
  _regex="${_regex}\(([^\)]*)\)[[:space:]]*"
  _regex="${_regex}([a-z]+\:)(<<([A-Za-z0-9_]+)|(.+))$"
  if [[ "${_line}" =~ $_regex ]]; then
    for _i in "${BASH_REMATCH[@]}"; do
      debug "INFO: ${_c}: ${_i}"
      _c=$((${_c} + 1))
    done
    _typename="${BASH_REMATCH[1]}"
    _funcname="${BASH_REMATCH[2]}"
    _args="${BASH_REMATCH[3]}"
    _scheme="${BASH_REMATCH[4]}"
    _jobdef=()
    _endmark="${BASH_REMATCH[6]}"
    local _c=0
    if [[ "${_endmark}" == "" ]]; then
      _jobdef="${BASH_REMATCH[7]}"
    else
      local _tail="${BASH_REMATCH[5]}"
      local _next
      while read -r _next ; do
	if [[ "${_next}" == "${_endmark}" ]]; then
	  break
	fi
    	_jobdef+=("${_next}")
      done
      local _i _c=0
    fi
  else
    quit "line ${LINENO}: Illegal line: ${_line}"
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
  echo "${_funcname}"
  echo "${_type}"
  # Encode spaces to semicolons not to confuse the caller
  echo "${_sinks// /\;}"
  echo "${_key}"
  # Encode spaces to semicolons not to confuse the caller
  echo "${_interpreter// /\;}"
  case "${_scheme}" in
    file:)
      local _filecontent=$(<${_jobdef})
      if [[ -z "${_filecontent}" ]]; then
	quit "file not found or the file is empty ${_jobdef}"
      fi
      echo $(pack_arr $'\n' "${_filecontent[@]}")
      ;;
    inline:)
      echo $(pack_arr $'\n' "${_jobdef[@]}")
      ;;
    *)
      quit "Unknown scheme is specified '${_scheme}'"
      ;;
  esac
}

. /usr/local/bin/bred-core

declare -r _ARRAY_SEPARATOR=$'\n'

read -r _l
read -r _id _type _sinks _key _interpreter _stask <<< $(read_xbred_func "$_l")
IFS=$'\n' _task=($(unpack_arr "${_stask}"))
echo "**TASK=${_task}**"
echo "id=${_id}"
echo "type=${_type}"
echo "_sinks=${_sinks}"
echo "_key=${_key}"
echo "_interpreter=${_interpreter}"
echo "_scheme=${_scheme}"
echo "_task=${_task})"
for _i in "${_task[@]}"; do
  echo "-->${_i}"
done
