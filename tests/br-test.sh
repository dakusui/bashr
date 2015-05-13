#!/bin/bash -u

####
# Global variables
BRED_BASEDIR="/tmp/bred"
TESTDIRNAME=$(dirname $0)
DIRNAME=$(dirname ${TESTDIRNAME})
SUT="${DIRNAME}/bred"
XSUT="${DIRNAME}/xbred"
NUM_TOTAL=0
NUM_PASSED=0

####
# A test executor
function exec_test() {
  NUM_TOTAL=$(($NUM_TOTAL + 1))
  local testcasename=$1
  if [ $(declare -F "$testcasename" | wc -l) != "1" ]; then
    echo "TESTRESULT:$testcasename:FAILED:Undefined"
    return 1
  fi
  local expected=$("${testcasename}" 'expected')
  local actual=$("${testcasename}" 'actual')
  local result=$(diff <(echo "$expected") <(echo "$actual"))
  if [ $? == 0 ] && [ -z "$result" ]; then
    NUM_PASSED=$(($NUM_PASSED + 1))
    echo "TESTRESULT:$testcasename:PASS"
  else
    echo "TESTRESULT:$testcasename:FAIL:$?:$result"
    echo "* EXPECTED:$expected"
    echo "* ACTUAL  :$actual"
  fi
}

function bredcheckenv_breddir_available() {
  if [ $1 == 'expected' ]; then
    echo 'OK'
  elif [ $1 == 'actual' ]; then
    if [[ -d "$HOME/.bred" ]]; then
      echo OK
    fi
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_nc_is_installed() {
  if [ $1 == 'expected' ]; then
    echo '1'
  elif [ $1 == 'actual' ]; then
    which nc | wc -l 
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_nc_supports_listen_mode() {
  if [ $1 == 'expected' ]; then
    echo '2'
  elif [ $1 == 'actual' ]; then
    nc -h 2>&1 | grep -e "-l" | grep listen | wc -l
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_pv_is_installed() {
  if [ $1 == 'expected' ]; then
    echo '1'
  elif [ $1 == 'actual' ]; then
    which pv | wc -l 
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_awk_is_installed() {
  if [ $1 == 'expected' ]; then
    echo '1'
  elif [ $1 == 'actual' ]; then
    which awk | wc -l 
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_passwordless_ssh_is_ok() {
  if [ $1 == 'expected' ]; then
    echo 'hello'
  elif [ $1 == 'actual' ]; then
    timeout 5 ssh localhost echo "hello"
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# Make sure your login shell is bash.
#
# Fix in case of fail:
# 1. Make sure bredcheckenv_passwordless_ssh_is_ok is passing.
# 2. Do 'chsh -s /bin/bash'
function bredcheckenv_loginshell_is_bash() {
  if [ $1 == 'expected' ]; then
    echo 'bash'
  elif [ $1 == 'actual' ]; then
    timeout 5 ssh localhost 'echo $0'
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredcheckenv_brp_is_installed() {
  if [ $1 == 'expected' ]; then
    echo '1'
  elif [ $1 == 'actual' ]; then
    which brp | wc -l
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}


####
# verify reducer is working
function bredtest_1reducer() {
  if [ $1 == 'expected' ]; then
    echo '0 BEGIN
0 BEGIN
0 BEGIN
1 MAIN 01 B
1 MAIN 02 A
1 MAIN 03 A
2 END
2 END
2 MAIN 01 C
3 END'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT" -m "localhost" -M reduce -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'  2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify reducer is working (sort_on_out disabled : -O no)
function bredtest_1reducer_sort_on_out_no() {
  if [ $1 == 'expected' ]; then
    echo '1 MAIN 01 B
1 MAIN 02 A
1 MAIN 03 A
2 MAIN 01 C'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost" -M reduce -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' -O no 2> /dev/null | sort | grep 'MAIN'
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify 2 reducers are working
function bredtest_2reducers() {
  if [ $1 == 'expected' ]; then
    echo '1 MAIN 01 B z
1 MAIN 02 A zz
1 MAIN 03 A x
2 MAIN 01 C y'
  elif [ $1 == 'actual' ]; then
    printf "03 A x\n02 A zz\n01 B z\n01 C y\n" | \
      "$SUT"  -m "localhost localhost" -M reduce -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' 2>/dev/null | grep "MAIN" | sort
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify 2 reducers are working with the thrid column as key
function bredtest_2reducersK3() {
  if [ $1 == 'expected' ]; then
    echo '1 MAIN 03 A x
1 MAIN 01 C y
1 MAIN 01 B z
1 MAIN 02 A zz'
  elif [ $1 == 'actual' ]; then
    printf "03 A x\n02 A zz\n01 B z\n01 C y\n" | \
      "$SUT"  -c 3 -m "localhost localhost" -M reduce -s 5 -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' 2>/dev/null | grep "MAIN"
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify mapper is working
function bredtest_1mapper() {
  if [ $1 == 'expected' ]; then
    echo '0 BEGIN
1 MAIN 03 A
2 MAIN 02 A
3 MAIN 01 B
4 MAIN 01 C
5 END'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost" -M map -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

# sort_on_out disabled (-O no)
function bredtest_1mapper_sort_on_out_no() {
  if [ $1 == 'expected' ]; then
    echo '0 BEGIN
1 MAIN 03 A
2 MAIN 02 A
3 MAIN 01 B
4 MAIN 01 C
5 END'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost" -M map -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' -O no 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify 2 mappers are working
function bredtest_2mappers() {
  if [ $1 == 'expected' ]; then
    echo '0 BEGIN
0 BEGIN
1 MAIN 02 A
1 MAIN 03 A
2 END
2 MAIN 01 B
3 MAIN 01 C
4 END'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost localhost" -M map -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify default sort
function bredtest_default_sort_default_column() {
  if [ $1 == 'expected' ]; then
    echo '01 B
01 C
02 A
03 A'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost localhost" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify default sort
function bredtest_default_sort_2nd_column() {
  if [ $1 == 'expected' ]; then
    echo '02 A
03 A
01 B
01 C'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost localhost" -c 2 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify 2 mappers are working with the third column specified as a key
function bredtest_2mappersK2() {
  if [ $1 == 'expected' ]; then
    echo '1 MAIN 01 B
1 MAIN 03 A
2 MAIN 02 A
3 MAIN 01 C
'
  elif [ $1 == 'actual' ]; then
    printf "03 A\n02 A\n01 B\n01 C\n" | \
      "$SUT"  -m "localhost localhost" -c 2 -M map -I 'awk -f' -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' 2>/dev/null | grep MAIN | sort -k 1,4
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify word count works with compat mode
function bredtest_compat_wordcount() {
  if [ $1 == 'expected' ]; then
    echo '      1 everyone
      3 hello
      1 one
      2 world'
  elif [ $1 == 'actual' ]; then
    printf "hello\nworld\neveryone\nhello\nhello\none\nworld" | \
      "$SUT"  -m "localhost" -r 'uniq -c' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify word count works with compat mode (sort_on_out disabled)
function bredtest_compat_wordcount_sort_on_out_disabled() {
  if [ $1 == 'expected' ]; then
    echo '      1 everyone'
  elif [ $1 == 'actual' ]; then
    printf "hello\nworld\neveryone\nhello\nhello\none\nworld" | \
      "$SUT"  -m "localhost" -r 'uniq -c' -O no 2> /dev/null | grep 'everyone' 
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

####
# verify word count works with compat mode (2 reducers)
function bredtest_compat_wordcount_with_2reducers() {
  if [ $1 == 'expected' ]; then
    echo '      1 everyone
      3 hello
      1 one
      2 world'
  elif [ $1 == 'actual' ]; then
    printf "hello\nworld\neveryone\nhello\nhello\none\nworld" | \
      "$SUT"  -m "localhost localhost" -r 'uniq -c' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function _format_bredfs() {
  local _fsbase="${BRED_BASEDIR:?BRED_BASEDIR must be set.}/fs"
  if [ -e "${_fsbase}" ]; then
    # Intentionally not to use variable _fsbase. I don't want to do 'rm -fr' by mistake.
    rm -fr "${BRED_BASEDIR}/fs/" 
    mkdir -p "${_fsbase}"
  fi
}

function bredtest_bredfs_init() {
  if [ $1 == 'expected' ]; then
    echo '====
/fs/0/path/to/store
/fs/1/path/to/store
/fs/2/path/to/store
/fs/3/path/to/store'
  elif [ $1 == 'actual' ]; then
    . "$(dirname $SUT)/bred-core"
    _format_bredfs
    find "${BRED_BASEDIR}/fs" -type f 2>/dev/null
    echo "===="
    # sort the output since the order doesn't matter
    STORE="/path/to/store" bredfs init 2>/dev/null
    find "${BRED_BASEDIR}/fs" -type f | sort | sed -E 's!'${BRED_BASEDIR}'!!g' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredtest_bredfs_write() {
  if [ $1 == 'expected' ]; then
    echo '==INIT==
/fs/0/path/to/store
/fs/1/path/to/store
/fs/2/path/to/store
/fs/3/path/to/store
==WRITE==
/fs/0/path/to/store:3 A WORLD
/fs/1/path/to/store:2 B HELLO
/fs/2/path/to/store:1 A HELLO
/fs/3/path/to/store:4 B WORLD'
  elif [ $1 == 'actual' ]; then
    . "$(dirname $SUT)/bred-core"
    _format_bredfs
    local _tmp=$(mktemp)
    echo 'A HELLO
B HELLO
A WORLD
B WORLD' > "${_tmp}"
    find "${BRED_BASEDIR}/fs" -type f | sort 2>/dev/null
    echo "==INIT=="
    # sort the output since the order doesn't matter
    STORE="/path/to/store" bredfs init 2>/dev/null
    find "${BRED_BASEDIR}/fs" -type f | sort | sed -E 's!'${BRED_BASEDIR}'!!g' 2>/dev/null
    echo "==WRITE=="
    # sort the output since the order doesn't matter
    APPEND="${_tmp}" TO="/path/to/store" bredfs write 2>/dev/null
    find "${BRED_BASEDIR}/fs" -type f -exec sh -c 'echo -n {}":" && cat {}' \; | sort  | sed -E 's!'${BRED_BASEDIR}'!!g' 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function bredtest_bredfs_read() {
  if [ $1 == 'expected' ]; then
    echo '==INIT==
/fs/0/path/to/store
/fs/1/path/to/store
/fs/2/path/to/store
/fs/3/path/to/store
==WRITE==
/fs/0/path/to/store:3 A WORLD
/fs/1/path/to/store:2 B HELLO
/fs/2/path/to/store:1 A HELLO
/fs/3/path/to/store:4 B WORLD
==READ==
A HELLO
A WORLD
B HELLO'
  elif [ $1 == 'actual' ]; then
    . "$(dirname $SUT)/bred-core"
    _format_bredfs
    local _tmp=$(mktemp)
    echo 'A HELLO
B HELLO
A WORLD
B WORLD' > "${_tmp}"
    find "${BRED_BASEDIR}/fs" -type f | sort 2>/dev/null
    echo "==INIT=="
    # sort the output since the order doesn't matter
    STORE="/path/to/store" bredfs init 2>/dev/null
    find "${BRED_BASEDIR}/fs" -type f | sort | sed -E 's!'${BRED_BASEDIR}'!!g'  2>/dev/null
    echo "==WRITE=="
    # sort the output since the order doesn't matter
    APPEND="${_tmp}" TO="/path/to/store" bredfs write 2>/dev/null
    find "${BRED_BASEDIR}/fs" -type f -exec sh -c 'echo -n {}":" && cat {}' \; | sort | sed -E 's!'${BRED_BASEDIR}'!!g' 2>/dev/null
    echo "==READ=="
    # sort the output since the order doesn't matter
    FROM="/path/to/store" WHERE="grep -E 'A|HELLO'" bredfs read | sort 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function xbredtest_xbred_01() {
  if [ $1 == 'expected' ]; then
    printf "     1\t"
  elif [ $1 == 'actual' ]; then
    echo "" | ${XSUT} "${TESTDIRNAME}/xbred-01/main.xbred" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function xbredtest_xbred_02() {
  if [ $1 == 'expected' ]; then
    printf "     1\t     1\t"
  elif [ $1 == 'actual' ]; then
    echo "" | ${XSUT} "${TESTDIRNAME}/xbred-02/main.xbred" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function xbredtest_xbred_03() {
  if [ $1 == 'expected' ]; then
    printf "     1\t     1\t     1\t"
  elif [ $1 == 'actual' ]; then
    echo "" | ${XSUT} "${TESTDIRNAME}/xbred-03/main.xbred" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function xbredtest_xbred_04() {
  if [ $1 == 'expected' ]; then
    printf "     1\t     1\t\n     1\t     1\t"
  elif [ $1 == 'actual' ]; then
    echo "" | ${XSUT} "${TESTDIRNAME}/xbred-04/main.xbred" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function xbredtest_xbred_06() {
  if [ $1 == 'expected' ]; then
    printf "value1
value2
value3.1 value3.2"
  elif [ $1 == 'actual' ]; then
    echo "" | ${XSUT} "${TESTDIRNAME}/xbred-06/main.xbred" 2>/dev/null
  else
    echo "Invalid mode $1 is specified"
    exit 1
  fi
}

function main() {
  if [[ $# > 0 ]]; then
    for each in $@ ; do
      exec_test "$each"
    done
  else
    echo "Running all defined tests"
    for each in $(declare -F | grep "bredcheckenv_" | cut -f 3 -d ' '); do
      exec_test "$each";
    done
    for each in $(declare -F | grep "bredtest_" | cut -f 3 -d ' '); do
      exec_test "$each";
    done
  fi
  echo "----"
  echo "TOTAL:$NUM_PASSED  / $NUM_TOTAL"
}

main $@
