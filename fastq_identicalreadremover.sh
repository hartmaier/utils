#!/bin/sh

#  fastq_identicalreadremover.sh
#
#
#  Created by Hartmaier, Ryan on 9/26/13.
#


basename=`basename $1 .fastq`

fa=`head -n 1 $1 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`
fb=`head -n 3 $1 | tail -n 1 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`

awk '{
  if($0~/^'''$fa'''/) {
    if(i>0) {
      printf "\n"$0
    } else {
      printf $0
    }
  } else {
    printf "\t"$0
  }
  i++
} END {
  printf "\n"
}' $1 | awk '{
  printf $0"\t"$1"\n"
}' | sort -s -k 1,1 | uniq -f 4 | awk '{
  printf $1"\n"$2"\n"$3"\n"$4"\n"
}' > $basename.unique.fastq
