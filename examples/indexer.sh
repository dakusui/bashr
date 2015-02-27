#!/bin/bash

find ${1:-$(pwd)} -type f -name ${2:-"*.txt"} |\
cat -n |pv | tee docid.txt |\
bred -c 3 -M map -j 0 -I 'awk' -r '{
  l=1;
  while(( getline line<$2) > 0 ) {
     gsub(/[[:punct:]]+/, " ", line);
     gsub(/[[:blank:]]+/, " ", line);
     n=split(line,cols," ");
     for (i = 2; i < n; i++) {
         print $1,l,cols[i]
     }
     l++;
  }
}' |pv | tee terms.txt |\
bred -c 3 -s 4 -O no -M reduce -j 1 -I 'awk' -r 'BEGIN {
    p=""
    key=""
}
{
    if (key == "") {
        key=$3;
    }
    p=p " " $1 "," $2
}
END {
    print "" key " [" ENVIRON["HOST_IDX"] "] " p;
}' -o index.txt



