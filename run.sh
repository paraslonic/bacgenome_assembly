# parameters
goodCov=150
miradir=/data3/bio/biouser/tools/mira_4/bin
fastqcdir=/data5/bio/knomics/soft/FastQC
cpus=$(grep "CPU" project.txt | sed -e 's/CPU *=//' -e 's/# \+//')

python python/run_check_file.py project.txt 

mkdir -p tmp
mkdir -p reads/rawreads
mv reads/*.f* reads/rawreads

# run fastqc
echo "runing fastqc..."
mkdir -p reads/fastqc
readfiles=$(ls reads/rawreads/*.f* | wc -l)
#$fastqcdir/./fastqc -f fastq -t $readfiles -out reads/fastqc reads/rawreads/*.f*

# trim 
echo "running trim"
perl helpers/runtrim.pl $cpus
rm output_forward_unpaired.fq
rm output_reverse_unpaired.fq

# subset 
bash helpers/subsetAndStat.sh

# run mira
mkdir -p assembly
mkdir -p assembly/mira
cat helpers/mira_head.txt > assembly/mira/manifest
sed -i "s/number_of_threads=15/number_of_threads=$cpus/g" assembly/mira/manifest
grep -v "#" project.txt >> assembly/mira/manifest
echo "mkdir /scratch/tmpmir; $miradir/./mira assembly/mira/manifest; mv mira_assembly/* assembly/mira/; rm mira_assembly" > tmp/runmira.sh
qsub -N Mira_process -cwd -e tmp/runmira.sh.e -o tmp/runmira.sh.o -pe make $cpus helpers/run_mira.sh

## run newbler
echo "perl helpers/run_newbler.pl $cpus" | qsub -N Newbler_process -cwd -e tmp/runnewbler.sh.e -o tmp/runnewbler.sh.o -pe make $cpus

# run spades
echo "perl helpers/run_spades.pl $cpus" | qsub -N Spades_process -cwd -e tmp/runspades.sh.e -o tmp/runspades.sh.o -pe make $cpus

echo "sh helpers/check_assembly_result.sh m" | qsub -hold_jid Mira_process -cwd -o tmp/check_assembly_mira_output -e tmp/check_assembly_mira_errors
echo "sh helpers/check_assembly_result.sh n" | qsub -hold_jid Newbler_process -cwd -o tmp/check_assembly_newbler_output -e tmp/check_assembly_newbler_errors
echo "sh helpers/check_assembly_result.sh s" | qsub -hold_jid Spades_process -cwd -o tmp/check_assembly_spades_output -e tmp/check_assembly_spades_errors

echo "" qsub -hold_jid Mira_process,Newbler_process,Spades_process -cwd -o tmp/wait_assm.e -e tmp/wait_assm.o
