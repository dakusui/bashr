#!/bin/bash

#######################################################################################################################
#
#          Distributed indexing with bred.
#          An example to index text files in a distributed manner using 'bred'
#
# Usage:   indexer.sh [1: A directory from which traversal starts] [2: File pattern] [3: index file]
#          1: I) Files under this directory are read and indexed (default = current directory)
#          2: I) Pattern to match files to be indexed (default='*.txt')
#          3: O) Index file. (default=stdout)
#
# Example: indexer.sh . '*.java' index.dat
#          This script indexes all the '*.java' files under the current directory
#          using the workers (hosts) listed in  /etc/br.hosts or ~/.br.hosts file.
#
# Prerequisites:
#          'bred' must be installed
#          /etc/br.hosts or ~/.br.hosts are configured correctly
#          The directory to be traversed must be visible to all the workers (hosts) listed in the br.hosts file at
#          the same path. E.g., the directory is an NFS share and it is mounted at the same point on all the host,
#          or hosts listed are all 'localhost'.
#
# Author:  dakusui@gmail.com ( https://github.com/dakusui/ )
#
#######################################################################################################################

eval dirname="${1:-$(pwd)}" # Expand ~ and . to an actual path.
find "$dirname" -type f -name ${2:-"*.txt"} |nl -w 1 -s ' ' -b a|tee docid.dat |pv |bred -e /dev/null -c 1 -s 3 -S1G -M map -j 0 -I 'awk' -r '{
  for (l=1; (getline line < $2) > 0; l++) {
     gsub(/([[:punct:]]|[[:blank:]])+/, " ", line);
     n=split(line,cols," ");
     for (i = 1; i <= n; i++) { print $1, l, cols[i]; };
  }
}' |tee terms.dat |pv |bred -e /dev/null -c 3 -s 1 -O no -M reduce -j 1 -S1G -I 'awk' -r 'BEGIN { p=""; key="";} {
  if (key == "") key=$3;
  p=p " " $1 "," $2
} END { print "" key " " p; }' ${3:+"-o $3"}

