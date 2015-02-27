#!/bin/bash -u

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
    local result=$(diff <(echo $expected) <(echo $actual))
    if [ $? == 0 ] && [ -z "$result" ]; then
        NUM_PASSED=$(($NUM_PASSED + 1))
	echo "TESTRESULT:$testcasename:PASS"
    else
	echo "TESTRESULT:$testcasename:FAIL:$?:$result"
        echo "* EXPECTED:$expected"
        echo "* ACTUAL  :$actual"
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
        nc -h |& grep -e "-l" | grep listen | wc -l
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}

function bredcheckenv_pv_is_nstalled() {
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
	"$SUT" -m "localhost" -j 0 -M reduce -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
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
	"$SUT" -m "localhost localhost" -j 0 -M reduce -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' | grep "MAIN" | sort
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
	"$SUT" -c 3 -m "localhost localhost" -j 0 -M reduce -s 5 -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' | grep "MAIN"
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
	"$SUT" -m "localhost" -j 0 -M map -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
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
	"$SUT" -m "localhost localhost" -j 0 -M map -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
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
	"$SUT" -m "localhost localhost" -j 0
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
	"$SUT" -m "localhost localhost" -j 0 -c 2
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
' | sort -k 1,4
    elif [ $1 == 'actual' ]; then
	printf "03 A\n02 A\n01 B\n01 C\n" | \
	"$SUT" -m "localhost localhost" -j 0 -c 2 -M map -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}' | grep MAIN | sort -k 1,4
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
	"$SUT" -m "localhost" -r 'uniq -c'
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
	"$SUT" -m "localhost localhost" -r 'uniq -c'
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}

DIRNAME=$(dirname $(dirname $0))
SUT=$DIRNAME/bred
NUM_TOTAL=0
NUM_PASSED=0

function main() {
    for each in $(declare -F | grep "bredcheckenv_" | cut -f 3 -d ' '); do
       exec_test $each;
    done
    for each in $(declare -F | grep "bredtest_" | cut -f 3 -d ' '); do
       exec_test $each;
    done
    echo "----"
    echo "TOTAL:$NUM_PASSED  / $NUM_TOTAL"
}
main $@
