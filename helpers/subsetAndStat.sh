mkdir -p reads/subset
rm readsStats.txt
GLength=$(grep "GLENGTH" project.txt | sed 's/.\+= *//g')
echo "genome length = $GLength"
COV=0

for f in reads/*.f*
do
        name=$(basename $f)
        head -4000 $f > reads/subset/$name
        meanLength=$(awk 'NR%4 == 2 {L=L+length($0)} END  {print L*4/NR}' reads/subset/$name)
        nreads=$(awk 'END {print NR/4}' $f )
        echo "$name     $nreads $meanLength" >> readsStats.txt
        cov=$(perl -e "print $meanLength*$nreads/$GLength")
        echo "coverage by this reads files is $cov" 
        COV=$( echo "$COV+$cov" | bc -l)
done
echo "overall coverage is $COV" >> readsStats.txt

#  !! TBD !! make a subset if reads count is too large


