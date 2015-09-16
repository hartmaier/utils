#!/bin/bash

#  circos2breakdown.sh
#
#
#  Created by Hartmaier, Ryan on 7/21/15.
#

usage () {
echo "
USAGE: $0
    -f [filename]       Input delly structural variation calls in circos format (written to accept vcf2circos output) (required)
    -h                  This help menu
"
}

while getopts ":f:h" option; do
  case ${option} in
    f)
      input_file=${OPTARG}
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "\nERROR: -${OPTARG} requires an argument"
      usage
      exit 1
      ;;
    ?)
      echo "\nERROR: unknown option -${OPTARG}"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$input_file" ] || [ ! -r "$input_file" ]; then
    echo -e "\nERROR: you must specify a valid input file name using -f"
    usage
    exit 1
fi

awk '
BEGIN {printf "%s\t%s\t%s\t%s\t%s\t%s\n","#chr1","start","chr2","end","type","size"}
{
  chr1=$1
  pos1=$2
  chr2=$4
  pos2=$5

  if ($7=="color=black") {
    type="DEL"
  } else if ($7=="color=blue") {
    type="INV"
  } else if ($7=="color=green") {
    type="DUP"
  } else if ($7=="color=red") {
    type="CTX"
  } else {
    type="other"
  }

  if (type != "CTX") {
    size=$5-$2
  } else {
    size=0
  }

  printf "%s\t%d\t%s\t%d\t%s\t%d\n",chr1,pos1,chr2,pos2,type,size

}' $input_file
