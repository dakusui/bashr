
letsgo() {
  for i in $@; do
    echo "--$i--"
  done
}

printit() {
  echo
  echo A
  echo B
  echo 
  echo C
}

countnumber() {
  echo "hello"
  return 100;
}

# echo $(countnumber)
# echo $?
# countnumber
# echo $?
# # letsgo $(printit)


printglobal() {
  global_v1="${global_v1} !! "
  echo "->"${global_v1}"<-"
}

# global_v1="hello"
# eval "printglobal"
# echo ${global_v1}

# if [ 0 ]; then
#   echo "0"
# fi

# if [ 1 ]; then
#   echo "1"
# fi


return_value0() {
  echo "hi"
  return 0
}

return_value1() {
  echo "hi"
  return 1
}

return_value1
r="$?"
if [[ "$r" == 0 ]]; then
  echo "1==0"
fi

return_value1
r="$?"
if [[ "$r" == 1 ]]; then
  echo "1==1"
fi

return_value0
r="$?"
if [[ "$r" == 0 ]]; then
  echo "0==0"
fi

return_value0
r="$?"
if [[ "$r" == 1 ]]; then
  echo "0==1"
fi

function rr() {
  echo rr
  return 100
}
rr
rr=$?
echo $rr


