#!/bin/bash

#  apobec_random.sh
#
#
#  Created by Hartmaier, Ryan on 7/30/15.
#

usage () {
echo "
USAGE: $0

This program will examine the trinucleotide context of a random portion of the genome.  It will output the C allele context and TCW context.  This is often used as a control for APOBEC enrichment calculations.

    -l [integer]    The length of the random region. (default=41)
    -s [integer]    Initial seed for random number generation.  Used to generate the same regions beteen runs (optional)
    -n [integer]    The total number of regions to generate. (default=10000)
    -g [filename]   Reference genome in fasta format.
    -r [filename]   Reference genome chromosome sizes.  Get with: mysql --user=genome --host=genome-mysql.cse.ucsc.edu -A -e \"select chrom, size from hg19.chromInfo\"  > hg19.genome
    -h              This help menu
"
}

length=41
num=10000
seed=123

while getopts ":l:n:s:g:r:h" option; do
    case ${option} in
        l)
            length=${OPTARG}
            ;;
        n)
            num=${OPTARG}
            ;;
        s)
            seed=${OPTARG}
            ;;
        g)
            ref_genome=${OPTARG}
            ;;
        r)
            chrom_len=${OPTARG}
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

rand_total=$[$num*2]
random_bed=`echo "random.C.$[$length-1]bp-window.bed"`

bedtools random -l $length -n $rand_total -seed 1127 -g $chrom_len | bedtools getfasta -fi $ref_genome -bed /dev/stdin -fo /dev/stdout -tab | awk -v total=$total '{
  seq_string=toupper($2)
  split($2,seq_array,"")
  i=0
  # print seq[21]
  if(toupper(seq_array[21])=="C" && index(seq_string,"N")==0) {
    c+=1
    split($1,temp,":")
    chr=temp[1]
    split(temp[2],z,"-")
    start=z[1]
    end=z[2]
    # print "count="c
    print chr"\t"start"\t"end
    # print seq_string
  }
  if(c==total) {
    exit
  }
}' > $random_bed

# Count the number of times C (or G) is present within the 40bp window
c_context=0
for nuc in C G
do
  count=`bedtools nuc -pattern $nuc -C -fi $ref_genome -bed $random_bed | awk '!/^#/{sum+=$13} END {print sum}'`
  c_context=$[$c_context+$count]
done
echo "C context=$c_context"

tcw_context=0
for tri in TCA TCT AGA TGA
do
  # echo $tri
  count=`bedtools nuc -pattern $tri -C -fi $ref_genome -bed $random_bed | awk '!/^#/{sum+=$13} END {print sum}'`
  tcw_context=$[$tcw_context+$count]
done
echo "TCW context=$tcw_context"
