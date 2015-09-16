#!/bin/sh

#  readcount2sciclone.sh
#  
#
#  Created by Hartmaier, Ryan on 11/11/14.
#

usage () {
echo "

Run the following awk command on bam-readcount output first:

awk '{split(\$6,a,\":\");split(\$7,c,\":\");split(\$8,g,\":\");split(\$9,t,\":\");print \$1\"\\\t\"\$2-1\"\\\t\"\$2\"\\\t\"\$3\"\\\t\"\$4\"\\\t\"a[2]\"\\\t\"c[2]\"\\\t\"g[2]\"\\\t\"t[2]}'

This outputs to stdout the following

chr position    Ref_allele  Variant_allele  Ref_allele_reads    Variant_allele_reads    VAF Filename

USAGE: $0
    -f [filename]   Input processed bam-readcount file (required)
    -h              This help menu
"
}

while getopts ":f:h" option; do
    case ${option} in
    f)
        in_file=${OPTARG}
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

if [ -z "$in_file" ] || [ ! -r "$in_file" ]; then
    echo "\nERROR: you must specify a valid input file name using -f"
    usage
    exit 1
fi

b_name=`basename $in_file`

awk -v b_name=$b_name '{
    ref_base=toupper($4)
    if(ref_base=="A") ref_col=6
    else if(ref_base=="C") ref_col=7
    else if(ref_base=="G") ref_col=8
    else if(ref_base=="T") ref_col=9

    ref=$ref_col
    alt=0
    alt_base=""
    for (i=6; i<=9; i++) {
        if(i!=ref_col){
            if($i>alt){
                alt=$i
#                print i
                if(i == 6) alt_base="A"
                else if(i == 7) alt_base="C"
                else if(i == 8) alt_base="G"
                else if(i == 9) alt_base="T"
            }
        }
    }
    if(alt==0){
        vaf=0
        alt_base="N/A"
    } else {
        vaf=alt/(alt+ref)*100
    }
    print $1"\t"$3"\t"ref_base"\t"alt_base"\t"ref"\t"alt"\t"vaf"\t"b_name
}' $in_file
