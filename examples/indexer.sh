#!/bin/bash

#
# Distributed indexing with bred.
#
# Usage:   indexer.sh [1: A directory from which traversal starts] [2: File pattern] [3: ndex file]
#          1: Files under this directory are read and indexed
#          2: Pattern to match files to be indexed
#
# Example: indexer.sh . '*.java' index.txt
#          This script indexes all the '*.java' files under the current directory
#          using the workers (hosts) listed in  /etc/br.hosts or ~/.br.hosts file.
#

eval dir=${1:-$(pwd)}
index=${3:+"-o $3"}
find $dir -type f -name ${2:-"*.txt"} |\
cat -n |pv | tee docid.txt | bred -c 3 -M map -j 0 -I 'awk' -r '{
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
}' |pv | tee terms.txt | bred -c 3 -s 4 -O no -M reduce -j 1 -I 'awk' -r 'BEGIN {
    p=""
    key=""
} {
    if (key == "") {
        key=$3;
    }
    p=p " " $1 "," $2
} END {
    print "" key " [" ENVIRON["HOST_IDX"] "] " p;
}' ${index}



