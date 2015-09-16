#!/bin/bash

#  vcf2circos.sh
#  
#
#  Created by Hartmaier, Ryan on 3/27/14.
#

usage () {
echo "
USAGE: $0
    -v [filename]   Input delly structural variation calls: .vcf (required)
    -o [path]       Path to output directory (optional, default is current directory)
    -n [basename]   Basename for output file (optional - if not set, will default to file name)
    -p              Filter only precise (split-read supported) SVs
    -r [readcount]  Minimum number of variant reads required (default is zero)
    -l [size]       SV length size cutoff (default=500)
    -a [freq]       Alternate allele frequency min (default=0)
    -z [filename]   Designate which sample in VCF file is the normal sample, if any (1-based numbering)
    -m [freq]       Alternate allele frequency max (this tags SVs identified with alt. freq greater than this. Can be used as a filter of germline events) (default=1)
    -h              This help menu
"
}
# Define default values
precise=0
read_cutoff=0
sv_len=500
alt_freq=0
max_alt_freq=1
normal_pos=0

while getopts ":v:o:n:pr:l:a:z:m:h" option; do
    case ${option} in
        v)
            vcf=${OPTARG}
            ;;
        o)
            out_dir=${OPTARG}
            ;;
        n)
            base_name=${OPTARG}
            ;;
        p)
            precise=1
            ;;
        r)
            read_cutoff=${OPTARG}
            ;;
        l)
            sv_len=${OPTARG}
            ;;
        a)
            alt_freq=${OPTARG}
            ;;
        z)
            normal_pos=${OPTARG}
            ;;
        m)
            max_alt_freq=${OPTARG}
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

if [ -z "$vcf" ] || [ ! -r "$vcf" ]; then
    echo -e "\nERROR: you must specify a valid input file name using -v"
    usage
    exit 1
fi

if [ -z "$base_name" ]; then
    base_name=$vcf
fi

#if [ ! -d "$out_dir" ]; then
#    echo -e "\nWARNING: -o was not specified or is not valid, using current directory for output"
#    out_dir="."
#fi

#if [ ! -d "$out_dir/conf" ]; then
#    mkdir $out_dir/conf
#fi
#
#if [ ! -d "$out_dir/images" ]; then
#    mkdir $out_dir/images
#fi


# Test if we could potentially append to an existing file
#file_test=$(ls ./$out_dir/$base_name* 2> /dev/null | wc -l)
#if [ $file_test -ne 0 ]; then
#    echo -e "\nBase name: $base_name matches potentially overlaps with files already present, please either delete those files, or choose another base name"
#usage
#   exit 1
#fi


# Generate Link Files, columns are as follows
# 1: $1
# 2: $2
# 3: $2+1
# 4: $8 -> CHR2
# 5: $8 -> END
# 6: $8 -> END+1
# 7: color based on $5

awk -v base_name=$base_name -v out_dir=$out_dir -v precise=$precise -v read_cutoff=$read_cutoff -v sv_len=$sv_len -v alt_freq=$alt_freq -v max_alt_freq=$max_alt_freq -v normal_pos=$normal_pos '{
    if ($0!~/^\##/) {
        if ($0~/^#/) {
            for (i = 10; i <= NF; i++) {
                samples[i-9]=$'i'
            }
        } else {
            if ($7=="PASS"){
                sv_pass=1
            } else {
                sv_pass=0
            }
            if ($5=="<DEL>") {
                color="black"
            } else if ($5=="<DUP>") {
                color="green"
            } else if ($5=="<INV>") {
                color="blue"
            } else if ($5=="<TRA>") {
                color="red"
            }

            sv_type=substr($5,2,3)

            split($8,a,";");
            sv_precise=0;
            sv_len_pass=0
            for (x in a) {
                split(a[x],b,"=");
                if (b[1]=="CHR2") {
                    chr2=b[2]
                } else if (b[1]=="END") {
                    end=b[2]
                } else if (b[1]=="CONSENSUS") {
                    sv_precise=1
                } else if (b[1]=="SVLEN" && (b[2]>sv_len || $5=="<TRA>")) {
#                } else if (b[1]=="SVLEN" && b[2]>sv_len) {
                    sv_len_pass=1
                    line_sv_len=b[2]
                }
            }
            l=split($9,format_test,":")
            dv_pos=""
            dr_pos=""
            for (y=1; y<=l; y++) {
                if (format_test[y]=="DV") {
                    dv_pos=y
                }
                if (format_test[y]=="DR") {
                    dr_pos=y
                }
            }
            if (dv_pos=="") {
                print "ERROR: Count not find DV: high quality variant pairs"
                exit 1
            }
            max_allele_marked=0

            # For this SV, look through each sample to determine if there is evidence that the SV is present, output the SV in a file for each sample if enough evidence is found.
            for (sample = 10; sample <= NF; sample++) {
                split($'sample',c,":");

                # The SV must be marked as PASS and is marked as precise (if flag is used)
                if (sv_pass==1 && sv_len_pass==1 && ((precise==1 && sv_precise==1) || precise==0) ) {
                    if (c[dv_pos]==0 && c[dr_pos]==0) {
                        freq=0
                    } else {
                        freq=c[dv_pos]/(c[dv_pos]+c[dr_pos])
                    }

                    # Make a separate output file for SVs with any evidence in normal sample, regardless of allele frequency or readcount cutoffs
                    if (normal_pos>0 && sample==normal_pos+9 && c[dv_pos]>0) {
                        out_normal=out_dir "/" base_name "[" samples[sample-9] "]." sv_type ".normal.circos";
                        out_normal_delly=out_dir "/" base_name "[" samples[sample-9] "]." sv_type ".normal.delly";
                        printf "%s\t%d\t%d\t%s\t%d\t%d\t%s\t%f\n",$1,$2,$2+1,chr2,end,end+1,"color="color,freq >> out_normal
                        print >> out_normal_delly
                    }

                    # Output SVs that meet read and allele frequency cutoffs for each sample
                    if (c[dv_pos]>read_cutoff && freq>alt_freq) {
                        out=out_dir "/" base_name "[" samples[sample-9] "]." sv_type ".circos";
                        out_temp=out_dir "/" base_name "[" samples[sample-9] "]." sv_type ".orig.filtered.txt";
                        out_filtered=out_dir "/" base_name "[" samples[sample-9] "]." sv_type ".max-allele.filtered.circos";

                        # Create a separtate output file containing SVs that are filter due to being over max allele frequency filter
                        if (max_allele_marked==0 && freq>max_alt_freq) {
                            color_marked="vvl"color
                            max_allele_marked=1
                            printf "%s\t%d\t%d\t%s\t%d\t%d\t%s\t%f\n",$1,$2,$2+1,chr2,end,end+1,"color="color_marked,freq >> out_filtered

                        # All other SVs get put into the main outfile file
                        } else {
                            printf "%s\t%d\t%d\t%s\t%d\t%d\t%s\t%f\n",$1,$2,$2+1,chr2,end,end+1,"color="color,freq >> out
                        }
                        print >> out_temp
#                        print "ref="c[dr_pos]
#                        print "var="c[dv_pos]
#                        print "al_freq="freq
#                        print "sv_len="line_sv_len
                    }
                }
            }
        }
    }
}' $vcf