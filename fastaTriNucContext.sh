#!/bin/sh

#  fastaTriNucContext.sh
#  
#
#  Created by Hartmaier, Ryan on 4/27/15.
#

usage () {
echo "
USAGE: $0

This program is designed to work on a MAF file from TCGA data.  It will output a file containing the context of the filter mutations (*.mutcontext) and a summary of this to (*.summary).

    -f [filename]   (required) TCGA MAF file.  This was written based on MAF version 2.4.  This program assumes two lines of headers (one line verson header and one line column header)
    -r [filename]   (required) Reference genome to extract nucleotide context
    -o              Output basename
    -h              This help menu
"
}

input="/dev/stdin"

while getopts ":f:r:o:h" option; do
    case ${option} in
        f)
            input=${OPTARG}
            ;;
        r)
            ref_genome=${OPTARG}
            ;;
        o)
            output=${OPTARG}
            ;;

        h)
            usage
            exit 0
            ;;
        :)
            echo -e "\nERROR: -${OPTARG} requires an argument"
            usage
            exit 1
            ;;
        ?)
            echo -e "\nERROR: unknown option -${OPTARG}"
            usage
            exit 1
            ;;
    esac
done

# This assumes 2 header lines which is standard in MAF files from TCGA.  A BED file is generated containing the coordinates for the trinucleotide context for each mutation.
tail -n +3 $input | awk '{print "chr"$5"\t"$6-2"\t"$6+1"\t"$5"_"$7"_"$12"_"$13}' > $output.context.bed

# getfasta is run on the previously generated BED file.  Output is piped to awk for analysis.
bedtools getfasta -tab -name -fi $ref_genome -bed $output.context.bed -fo /dev/stdout | awk -v out=$output '{

    # Extract mutation location
    split($1,name,"_")
    chr="chr"name[1]
    mut_pos=name[2]

    # Extract WT and mutant alleles
    ref=name[3]
    mut=name[4]
    out1=out".mutcontext"
    l=split(toupper($2),context,"")
    if (l !=3 || length(ref) != 1 || length(mut) != 1 || mut == "-" || mut == "N" || ref == "-") {next}

    # These two lines create an array called trinucs of length 4 composed of the following elements:
    #   1. 5 prime nucleotide
    #   2. Reference allele
    #   3. Mutant allele
    #   4. 3 prime nucleotide
    temp=context[1]"_"context[2]"_"mut"_"context[3]
    split(temp,trinucs,"_")

    # If the reference allele for the mutation is A or G, do reverse complement of the sequence
    if(ref=="A" || ref=="G") {
        for (i in trinucs) {
            if (trinucs[i]=="A") comp[5-i]="T";
            else if (trinucs[i]=="T") comp[5-i]="A";
            else if (trinucs[i]=="C") comp[5-i]="G";
            else if (trinucs[i]=="G") comp[5-i]="C";
            else comp[5-i]="N"     # should never happen
        }
        print chr":"mut_pos"\t"comp[1]"\t"comp[3]"->"comp[2]"\t"comp[4] >> out1
    } else {
        print chr":"mut_pos"\t"trinucs[1]"\t"trinucs[2]"->"trinucs[3]"\t"trinucs[4] >> out1
    }
}'

cut -f 2-4 $output.mutcontext | sort | uniq -c | sed 's/^ *//' | tr " " "\t" > $output.summary