#!/bin/bash

find /home/hiroshi/Documents/IdeaProjects/jcunit/ -type f -name '*.java' |\
cat -n |\
tee docid.txt |\
br -c 3 -M map -j 0 -I 'awk' -r '{
  l=1;
  while(( getline line<$2) > 0 ) {
     sub(/[[:punct:]]/, " ", line);
     sub(/[[:blank:]]+/, " ", line);
     n=split(line,cols," ");
     for (i = 1; i < n; i++) {
         print $1,l,cols[i]
     }
     l++;
  }
}' |\
tee terms.txt |\
br -c 3 -s '-n' -O no -M reduce -j 1 -I 'awk' -r 'BEGIN {
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



