#!/bin/sh

#  ccle_snp_gene_correlation.sh
#
#
#  Created by Hartmaier, Ryan on 5/28/15.
#

usage () {
echo "
USAGE: $0

This program takes generates a matrix of genotype calls across CCLE cell lines.  Meant to be used to look at genotypes for a limited number of SNPs across all cell lines.

    -f [filename]   (required) CCLE file to cell line key file.  Format is (1) Affy6.0 filename, (2) cell line.  Additional columns will be ignored.  Expects no header to be present.
    -r [filename]   (required) SNP file(s).  Format is (1) SNPid, (2) genotype call, (3) confidence, (4) filename.  Multiple files can be added as a comma separated list.
    -o              (required) Output file
    -h              This help menu
"
}

input="/dev/stdin"

while getopts ":f:r:o:h" option; do
    case ${option} in
        f)
            key_file=${OPTARG}
            ;;
        r)
            snp_file_list=${OPTARG}
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

num_snp_files=`echo $snp_file_list | awk -F ',' '{print NF}'`

# Construct header
out_line[0]="CellLine"
for ((i=1;i<=$num_snp_files;++i))
do
    out_line[$i]=`echo $snp_file_list | cut -d ',' -f $i`
done
IFS=$'\t';  printf "%s\n" "${out_line[*]}" > $output


while read line
do
    file_query=`echo $line | cut -d ' ' -f 1`
    cell_line=`echo $line | cut -d ' ' -f 2`
    out_line[0]=$cell_line
    for ((i=1;i<=$num_snp_files;++i))
    do
        file_test=`echo $snp_file_list | cut -d ',' -f $i`
        out_line[$i]=`grep -m 1 $file_query $file_test | cut -f 2`
    done
    IFS=$'\t';  printf "%s\n" "${out_line[*]}" >> $output
done < $key_file
