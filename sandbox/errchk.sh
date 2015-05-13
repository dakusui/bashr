function error_check() {
  local _pipestatus="${PIPESTATUS[@]}"
  local _exitcode=$?
  for _i in "${_pipestatus[@]}"; do
    if [[ ! "$_i" == 0 ]]; then
      echo "exitcode=${_exitcode}: pipestatus=${_pipestatus[@]}" >& 2
      return 1
    fi   
  done
  return ${_exitcode} 
}

error_check2() {
  local _pipestatus="${PIPESTATUS[@]}"
  local _exitcode=$?
  for _i in "${_pipestatus[@]}"; do
    if [[ ! "$_i" == 0 ]]; then
      echo "exitcode=${_exitcode}: pipestatus=${_pipestatus[@]}" >& 2
      return 1
    fi   
  done
  return ${_exitcode} 
}
