large_contigs_filename=assembly/newbler_large/assembly/454LargeContigs.fna
receivers=$(grep -E "#.*@" project.txt | sed -e 's/# *//')

if [ -s $large_contigs_filename ]
then
	Assembly_Stats=$(assemblyStats.pl $large_contigs_filename) 
	Assembly_Stats=${Assembly_Stats//"max"/"max<br/>"}
	mail_body="Working directory: $PWD <br/> $Assembly_Stats"
else
	mail_body="Working directory: $PWD <br/> No large contigs"
fi

if [ -s tmp/cluster_contigs.sh.e ]
then
	mail_files="Contamination.pdf tmp/cluster_contigs.sh.e"
else
	mail_files="Contamination.pdf"
fi

python python/run_send_mail.py -s "Fast Newbler assembly result" -f $mail_files -b "$mail_body" -r $receivers
