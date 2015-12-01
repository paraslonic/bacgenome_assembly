large_contigs_filename=assembly/newbler_large/assembly/454LargeContigs.fna
num_points=$1
cpus=$2

# fasta newbler assembly
echo "$(date +"%d-%m-%y %T") Start fast newbler assembly cpu=$cpus"
perl helpers/run_newbler.pl $cpus large
echo "$(date +"%d-%m-%y %T") Start cluster analysis num_points=$num_points"

rm -f Contamination*
rm -f plasmids.fasta
rm -f *_cluster.fasta

if [ -s $large_contigs_filename ]
then
	#find clusters
	Rscript helpers/cluster_contigs.R -p $PWD -n $num_points --grid	
fi

echo "$(date +"%d-%m-%y %T") End cluster analysis"
 

