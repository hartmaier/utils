#!/bin/bash

#  GASVpro2BEDPE.sh
#  
#
#  Created by Hartmaier, Ryan on 3/18/14.
#

usage () {
echo -e "\nUSAGE: $0\n\t-i [filename]\tInput structural variation calls: .pruned.clusters file from GASVpro (required)\n\t-g\t\tOutput file in .gasvbedpe (bedpe format + additional columns with GASVpro parameters)(required if -b is not set)\n\t-b\t\tOutput file in .bedpe format (no additional columns)(required if -g is not set)\n\t-n [basename]\tBasename for each file (optional - if not set, will default to file name)\n\t-h\t\tThis help menu\n"
}

gasvbedpe=0
bedpe=0

while getopts ":i:gbn:h" option; do
    case ${option} in
        i)
            sv_file=${OPTARG}
            ;;
        g)
            gasvbedpe=1
            ;;
        b)
            bedpe=1
            ;;
        n)
            base_name=${OPTARG}
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

if [ -z "$sv_file" ] || [ ! -r "$sv_file" ]; then
echo -e "\nERROR: you must specify a valid input file name using -i"
usage
exit 1
fi

if [ $gasvbedpe -eq 0 ] && [ $bedpe -eq 0 ]; then
echo -e "\n WARNING: no output type entered, defaulting to bedpe format\n"
bedpe=1
fi

if [ -z "$base_name" ]; then
base_name=$sv_file
fi

if [ $gasvbedpe -eq 1 ] && [ $bedpe -eq 1 ]; then
awk '{split($3,a,","); split($5,b,","); if ($0!~/^#/) {printf "%s\t%d\t%d\t%s\t%d\t%d\n","chr"$2,a[1],a[2],"chr"$4,b[1],b[2] > "'''$base_name'''.bedpe"; printf "%s\t%d\t%d\t%s\t%d\t%d\t%d\t%f\t%s\t%d\n","chr"$2,a[1],a[2],"chr"$4,b[1],b[2],$6,$7,$8,$9 > "'''$base_name'''.gasvbedpe" }}' $sv_file
elif [ $gasvbedpe -eq 1 ]; then
awk '{split($3,a,","); split($5,b,","); if ($0!~/^#/) {printf "%s\t%d\t%d\t%s\t%d\t%d\t%d\t%f\t%s\t%d\n","chr"$2,a[1],a[2],"chr"$4,b[1],b[2],$6,$7,$8,$9 > "'''$base_name'''.gasvbedpe" }}' $sv_file
elif [ $bedpe -eq 1 ]; then
awk '{split($3,a,","); split($5,b,","); if ($0!~/^#/) {printf "%s\t%d\t%d\t%s\t%d\t%d\n","chr"$2,a[1],a[2],"chr"$4,b[1],b[2] > "'''$base_name'''.bedpe"}}' $sv_file
fi