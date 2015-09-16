#!/bin/bash

#  GASVpro2LFF.sh
#  
#
#  Created by Hartmaier, Ryan on 3/21/14.
#

usage () {
echo -e "\nUSAGE: $0\n\t-i [filename]\tInput structural variation calls: .pruned.clusters file from GASVpro (required)\n\t-n [basename]\tBasename for each file (optional - if not set, will default to file name)\n\t-h\t\tThis help menu\n"
}

gasvbedpe=0
bedpe=0

while getopts ":i:gbn:h" option; do
    case ${option} in
        i)
            sv_file=${OPTARG}
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

if [ -z "$base_name" ]; then
base_name=$sv_file
fi

# here....need to figure out orientation for LFF format...
# LFF format is:
#   1. Class (i.e. 'structural variations' (string)
#   2. Name (i.e. structural variation identifier, must be identical for paired breakpoints) (string)
#   3. Type (i.e. inverstion, deletion, translation, etc) (string)
#   4. SubType (i.e. IR, I-, I+, TR+, etc) (see GASVpro user guide) (string)
#   5. Entry point (chromosome) (string)
#   6. Start (start coordinate) (integer)
#   7. Stop (end coordinate) (integer)
#   8. Strand (string)
#   9. Phase (always . in this case) (string)
#   10. Score (always 1.0 in this case) (float)

awk -v f=$flank_size '{
    split($3,a,",");
    split($5,b,",");
    if ($0!~/^#/)
        if ($8 == "D")
            printf "%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%1.1f\n","SV",$1,"Deletion",$8,"chr"$2,a[1],a[1],"+",".",1.0 >> "'''$base_name'''.lff"
            printf "%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%1.1f\n","SV",$1,"Deletion",$8,"chr"$2,b[2],b[2],"-",".",1.0 >> "'''$base_name'''.lff"

        if ($8 == "IR")
            printf "%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%1.1f\n","SV",$1,"Inversion",$8,"chr"$2,a[1],a[2],"+",".",1.0 >> "'''$base_name'''.lff"
            printf "%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%1.1f\n","SV",$1,"Inversion",$8,"chr"$2,b[1],b[2],"-",".",1.0 >> "'''$base_name'''.lff"


c[$2],a[1],a[2],c[$4],b[1],b[2],$6,$7,$8,$9 > "'''$base_name'''.gasvbedpe"






}' $sv_file
