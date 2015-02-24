#!/bin/bash

# find /home/hiroshi/Documents/IdeaProjects/jcunit/ -type f -name '*.java' |\
echo ~/Documents/IdeaProjects/bashreduce/../jcunit/src/main/java/com/github/dakusui/jcunit/fsm/Action.java |\
cat -n |\
tee docid.txt |\
br -s '-n' -M map -j 0 -I 'awk' -r '{
  l=1;
  while(( getline line<$2) > 0 ) {
     n=split(line,cols);
     for (i = 1; i < n; i++) {
         print $1,l,cols[i]
     }
     l++;
  }
}' |\
tee terms.txt |\
br -s '-n' -c 3 -M reduce -j 1 -I 'awk' -r 'BEGIN {
}
{
    print $0;
}
END {
}'



