##Map common reads

basename1=` echo $1 | sed s/.fastq$// `
basename2=` echo $2 | sed s/.fastq$// `
f1a=`head -n 1 $1 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`
f2a=`head -n 1 $2 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`

echo "f1a="$f1a
echo "f2a="$f2a

f1b=`head -n 3 $1 | tail -n 1 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`
f2b=`head -n 3 $2 | tail -n 1 | cut -d ":" -f 1 - | cut -d "_" -f 1 -`

echo "f1b="$f1b
echo "f2b="$f2b

(
echo `date "+%Y/%m/%d @ %H:%M:%S"` " ==> Tab file generation"
awk '
{
    if($0~/'''$f1a'''/) {
        if(i>0){
            printf "\n"$0
        }else{
            printf $0
        }
    }else{
        printf "\t"$0
    };i++
}
END{printf "\n"}' $1 > $basename1"_tab.tab" &



awk '{if($0~/'''$f2a'''/){if(i>0){printf "\n"$0}else{printf $0}}else{printf "\t"$0};i++}END{printf "\n"}' $2 > $basename2"_tab.tab" &
) 2>&1 | cat

(
echo `date "+%Y/%m/%d @ %H:%M:%S"` " ==> Formatted tab file generation"
awk -v fa=$f1a -v fb=$f1b -F $'\t' '{printf fa; split($1,a,"/");split(a[1],b,":"); for (i=2;i<=NF;i++) printf ":"b[i+1]; printf "\t"$2"\t"; printf fb; split($3,a,"/");split(a[1],b,":"); for (i=2;i<=NF;i++) printf ":"b[i+1]; printf "\t"$4"\n"}' $basename1"_tab.tab" > $basename1"_tab.txt" &
awk -v fa=$f2a -v fb=$f2b -F $'\t' '{printf fa; split($1,a,"/");split(a[1],b,":"); for (i=2;i<=NF;i++) printf ":"b[i+1]; printf "\t"$2"\t"; printf fb; split($3,a,"/");split(a[1],b,":"); for (i=2;i<=NF;i++) printf ":"b[i+1]; printf "\t"$4"\n"}' $basename2"_tab.tab" > $basename2"_tab.txt" &
) 2>&1 | cat

(
echo `date "+%Y/%m/%d @ %H:%M:%S"` " ==> Sorting"
sort -t $'\t' -f -k 1,1 $basename1"_tab.txt" > $basename1"_sorted_tab.txt" &
sort -t $'\t' -f -k 1,1 $basename2"_tab.txt" > $basename2"_sorted_tab.txt" &
) 2>&1 | cat

(
echo `date "+%Y/%m/%d @ %H:%M:%S"` " ==> Generating matched and orphan read files"
join -t $'\t' -1 1 -2 1 $basename1"_sorted_tab.txt" $basename2"_sorted_tab.txt" | awk -F $'\t' -v basename1=$basename1 -v basename2=$basename2 '{print $1"/1\n"$2"\n"$3"/1\n"$4 > basename1"_matched.fastq"; print $5"/2\n"$6"\n"$7"/2\n"$8 > basename2"_matched.fastq"}' &
join -t $'\t' -v 1 -1 1 -2 1 $basename1"_sorted_tab.txt" $basename2"_sorted_tab.txt" | awk -F $'\t' -v basename1=$basename1 '{print $1"/1\n"$2"\n"$3"/1\n"$4 > basename1"_ORPHAN.fastq"}' &
join -t $'\t' -v 2 -1 1 -2 1 $basename1"_sorted_tab.txt" $basename2"_sorted_tab.txt" | awk -F $'\t' -v basename2=$basename2 '{print $1"/2\n"$2"\n"$3"/2\n"$4 > basename2"_ORPHAN.fastq"}' &
) 2>&1 | cat

#rm $basename1"_tab.txt"
#rm $basename2"_tab.txt"
#rm $basename1"_sorted_tab.txt"
#rm $basename2"_sorted_tab.txt"
#rm $basename1"_tab.tab"
#rm $basename2"_tab.tab"





awk -v in=$file -v out=$f_out '{printf "%s\t%d\t%d",$1,$2,$3 >> out; print $0 > "tmp.bed"; system("bedtools intersect -a " " "in" " "-b tmp.bed")}' RDT.ROI.sort.merge.bed


