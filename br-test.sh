#!/bin/bash -u

DIRNAME=`dirname $0`

####
# A test executor
function execTest() {
    testcasename=$1
    result=$(diff <("${testcasename}" 'expected') <("${testcasename}" 'actual'))
    if [ $? == 0 ] && [ -z $result ]; then
	echo "TESTRESULT:$testcasename:PASS"
    else
	echo "TESTRESULT:$testcasename:FAIL:$?:$result"
    fi
}

####
# verify reducer is working
function test1reducer() {
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
	"$DIRNAME"/br -m "localhost" -j 0 -M reduce -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}
execTest "test1reducer"

####
# verify 2 reducers are working
function test2reducers() {
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
	"$DIRNAME"/br -m "localhost localhost" -j 0 -M reduce -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}
execTest "test2reducers"


####
# verify mapper is working
function test1mapper() {
    if [ $1 == 'expected' ]; then
	echo '0 BEGIN
1 MAIN 03 A
2 MAIN 02 A
3 MAIN 01 B
4 MAIN 01 C
5 END'
    elif [ $1 == 'actual' ]; then
	printf "03 A\n02 A\n01 B\n01 C\n" | \
	"$DIRNAME"/br -m "localhost" -j 0 -M map -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}
execTest "test1mapper"

####
# verify 2 mappers are working
function test2mappers() {
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
	"$DIRNAME"/br -m "localhost localhost" -j 0 -M map -I awk -r 'BEGIN{i=0;print i++,"BEGIN";} //{print i++,"MAIN",$0;} END{print i++,"END";}'
    else
        echo "Invalid mode $1 is specified"
        exit 1
    fi
}
execTest "test2mappers"

