#!/bin/sh

#  apobec_enrichment.sh
#
#
#  Created by Hartmaier, Ryan on 07/30/15.
#


usage () {
echo "
USAGE: $0

This program will take mutect output directly as input and filter by various parameters.  It will output a filtered mutect file remaining in mutect format (*.filtered) and converted to BED (*.filtered.bed).  It also outputs a file containing the context of the filter mutations (*.mutcontext) and a summary of this to (*.summary).

    -m [filename]   (required) mutcontext.bed file
    -r [filename]   (required) Reference genome fasta file
    -o              Output basename
    -h              This help menu
"
}

while getopts ":m:r:o:h" option; do
    case ${option} in
        m)
            mut_file=${OPTARG}
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

if [ -z $mut_file ]; then
    usage
    exit 0
fi

if [ -z $output ]; then
    echo "WARNING: No output basename specified, using 'output'."
    output="output"
fi



####################
### Main Program ###
####################

# Create new bed file for +/- 20bp around the mutation
awk '{
  print $1"\t"$2-20"\t"$3+20
}' $mut_file | sort -u > $output.40bp-window.bed

# Count the number of times TCW (or WGA) motif is present within the 40bp window
tcw_context=0
for tri in TCA TCT AGA TGA
do
  # echo $tri
  count=`bedtools nuc -pattern $tri -C -fi $ref_genome -bed $output.40bp-window.bed | awk '!/^#/{sum+=$13} END {print sum}'`
  tcw_context=$[$tcw_context+$count]
done

# Count the number of times C (or G) is present within the 40bp window
c_context=0
for nuc in C G
do
  count=`bedtools nuc -pattern $nuc -C -fi $ref_genome -bed $output.40bp-window.bed | awk '!/^#/{sum+=$13} END {print sum}'`
  c_context=$[$c_context+$count]
done

# Count the number of mutations impacting a TCW to TTW or TGW, WGA to WAA or WCA
tcw_mutations=`awk '{
  mut=$4
  if(mut=="TC->TA" || mut=="TC->TT" || mut=="TC->GA" || mut=="TC->GT" || mut=="AG->AA" || mut=="TG->AA" || mut=="AG->CA" || mut=="TG->CA") {
    sum+=1
  }
} END {print sum}' $mut_file`

# Count the number of mutations impacting a C to T or G, and G to A or C
c_mutations=`awk '{
  split($4,mut_array,"")
  mut=mut_array[2]mut_array[3]mut_array[4]mut_array[5]
  if(mut=="C->T" || mut=="C->G" || mut=="G->A" || mut=="G->C") {
    sum+=1
  }
} END {print sum}' $mut_file`

echo "TCW mutations=$tcw_mutations"
echo "C mutations=$c_mutations"
echo "TCW context=$tcw_context"
echo "C context=$c_context"

y=$(( $tcw_mutations * $c_context ))
z=$(( $c_mutations * $tcw_context ))

echo "APOBEC ENRICHMENT IS:"
echo "scale = 4; $y/$z" | bc
