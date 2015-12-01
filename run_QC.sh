# parameters
fastqcdir=/data5/bio/knomics/soft/FastQC
cpus=$(grep "CPU" project.txt | sed -e 's/CPU *=//' -e 's/# \+//')
num_points=30

python python/run_check_file.py project.txt

mkdir -p tmp

# run fastqc
echo "runing fastqc..."
mkdir -p reads/fastqc
readfiles=$(ls reads/*.f* | wc -l)
#$fastqcdir/./fastqc -f fastq -t $readfiles -out reads/fastqc reads/*.f*

cat /dev/null > tmp/cluster_contigs.sh.e
cat /dev/null > tmp/cluster_contigs.sh.o 
cat /dev/null > tmp/send_mail.sh.e
cat /dev/null > tmp/send_mail.sh.o

# fast newbler assembly and analyse clusters
echo "Start fast newbler assembly and cluster analysis"
echo "bash helpers/cluster_contigs_script.sh $num_points $cpus" | qsub -N Fast_Newbler_cluster -cwd -e tmp/cluster_contigs.sh.e -o tmp/cluster_contigs.sh.o -pe make $cpus
echo "bash helpers/send_mail.sh" | qsub -N Send_Mail -hold_jid Fast_Newbler_cluster -cwd -e tmp/send_mail.sh.e -o tmp/send_mail.sh.o -pe make 1

