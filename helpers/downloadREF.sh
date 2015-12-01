strain=$1

rsync -av rsync://ftp.ncbi.nlm.nih.gov/genomes/Bacteria --include "*/" --include "Bacteria/$strain*/*.fna" --exclude=* .
find Bacteria -name "*.fna" | while read i ; do cat "$i" >> `dirname "$i"`.fasta ; done
completes=$(ls Bacteria/*.fasta | wc -l)
echo "$completes complete genomes:" > refStats.txt
ls Bacteria/*.fasta >> refStats.txt 

rsync -av rsync://ftp.ncbi.nlm.nih.gov/genomes/Bacteria_DRAFT --include "*/" --include "Bacteria_DRAFT/$strain*/*.fna.tgz" --exclude=* .
find . -empty -type d -delete
find Bacteria_DRAFT -name "*.fna.tgz" | while read i ; do tar zxvf "$i" -C `dirname "$i"`; done
find Bacteria_DRAFT -name "*.fna.tgz" | while read i ; do dir=`dirname "$i"`; rm $dir.fasta; cat $dir/*.fna >> $dir.fasta; done
drafts=$(ls Bacteria_DRAFT/*.fasta | wc -l)
echo -e "\n$drafts draft genomes:" >> refStats.txt
ls Bacteria_DRAFT/*.fasta >> refStats.txt 
 
