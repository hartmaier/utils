#!/bin/sh

#  mutect_context.sh
#
#
#  Created by Hartmaier, Ryan on 10/7/14.
#


usage () {
echo "
USAGE: $0

This program will take mutect output directly as input and filter by various parameters.  It will output a filtered mutect file remaining in mutect format (*.filtered) and converted to BED (*.filtered.bed).  It also outputs a file containing the context of the filter mutations (*.mutcontext) and a summary of this to (*.summary).

    -m [filename]   (required) mutect output file
    -d              Include mutations found in dbSNP (default does not include)
    -u              Include mutations that are 'uncovered' (default does not include)
    -r              Include mutations that are 'rejected' (default does not include)
    -o              Output basename
    -h              This help menu
"
}

dbsnp=FALSE
uncovered=FALSE
rejected=FALSE

while getopts ":m:durf:o:h" option; do
    case ${option} in
        m)
            mutect=${OPTARG}
            ;;
        d)
            dbsnp=TRUE
            ;;
        u)
            uncovered=TRUE
            ;;
        r)
            rejected=TRUE
            ;;
        o)
            output=${OPTARG}
            ;;

        f)
            filt=${OPTARG}
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

if [ -z $mutect ]; then
    usage
    exit 0
fi

if [ -z $output ]; then
    echo "WARNING: No output basename specified, using 'output'."
    output="output"
fi

if [ -a "$output.filtered" ]; then
    rm $output.filtered
fi

if [ -a "$output.filtered.bed" ]; then
rm $output.filtered
fi

if [ -a "$output.mutcontext" ]; then
    rm $output.mutcontext
fi



awk -v out=$output -v dbsnp=$dbsnp -v uncovered=$uncovered -v rejected=$rejected -v filt=$filt '{
    line_r=$35
    line_d=$9
    line_u=$10

    ref=$4
    mut=$5
    split($3,context,"")

    include_line="FALSE"
    # test conditions that the line should be excluded
    if (dbsnp=="FALSE" && line_d=="DBSNP") include_line="FALSE";
    else if (uncovered=="FALSE" && line_u=="UNCOVERED") include_line="FALSE";
    else if (rejected=="FALSE" && line_r=="REJECT") include_line="FALSE";
    else {
        if (filt != "") {
            split(filt,filt_s,",")

            for (i in filt_s) {
                split(filt_s[i],filt_bases,"")

                for (j in filt_bases) {
                    if (filt_bases[j]=="A") filt_bases_revcomp[6-j]="T";
                    else if (filt_bases[j]=="T") filt_bases_revcomp[6-j]="A";
                    else if (filt_bases[j]=="C") filt_bases_revcomp[6-j]="G";
                    else if (filt_bases[j]=="G") filt_bases_revcomp[6-j]="C";
                    else if (filt_bases[j]=="-") filt_bases_revcomp[6-j]="-";
                    else filt_bases_revcomp[6-j]="N"
                }
                if ( (filt_bases[1]==context[3] && filt_bases[2]==ref && filt_bases[4]==mut && filt_bases[5]==context[5]) || (filt_bases_revcomp[1]==context[3] && filt_bases_revcomp[2]==ref && filt_bases_revcomp[4]==mut && filt_bases_revcomp[5]==context[5])) {

#                    print $3
#                    print "REF: "ref
#                    print "MUT: "mut
                    include_line="TRUE";
                }

            }
        } else include_line="TRUE";
    }

    out1=out".filtered"
    out2=out".mutcontext.bed"
    out3=out".filtered.bed"
#    out4=out".rnaseqmut.input.txt"

    if (include_line=="TRUE" && $1 !~ /^#/ && $1 !~ /^contig/) {
        print $0 >> out1
        print $1"\t"$2-1"\t"$2 >> out3
#        print $1"\t"$2-1"\t"$2"\t"$4"\t"$5 >> out4

        temp=context[3]"_"ref"_"mut"_"context[5]
        split(temp,orig,"_")

        if(ref=="A" || ref=="G") {
            for (i in orig) {
                if (orig[i]=="A") comp[5-i]="T";
                else if (orig[i]=="T") comp[5-i]="A";
                else if (orig[i]=="C") comp[5-i]="G";
                else if (orig[i]=="G") comp[5-i]="C";
                else comp[5-i]="N"     # should never happen
            }
            print $1"\t"$2-1"\t"$2"\t"comp[1]comp[3]"->"comp[2]comp[4] >> out2
#            print "COMPLEMENT"
#            print "ORIG: "orig[1] orig[2] orig[3] orig[4]
#            print "COMP: "comp[1] comp[2] comp[3] comp[4]

        } else {
            print $1"\t"$2-1"\t"$2"\t"orig[1]orig[2]"->"orig[3]orig[4] >> out2
#            print "NO COMPLEMENT"
#            print "ORIG: "orig[1] orig[2] orig[3] orig[4]
#            print "COMP: "comp[1] comp[2] comp[3] comp[4]
        }


    }
}' "$mutect"

cut -f 4 $output.mutcontext.bed | sort | uniq -c | sed 's/^ *//' | tr " " "\t" > $output.summary
