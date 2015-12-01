$THREADS = shift or $THREADS = 5;

@datas = `grep "data" project.txt`;

foreach(@datas){
	print "\n\n\n\n";
	chomp;
	/data\s+=\s+(.+)/;
	$str = $1;
	@outfiles = split(/\s/,$str);
	@infiles = @outfiles; 
	map { $_ =~ s/reads/reads\/rawreads/g } @infiles;
	$nfiles = scalar(@infiles);
	if($nfiles > 2) { print "--- more then 2 files in group! ---"; exit; }
	if($nfiles == 2) { 
		`trimmomatic  PE -threads $THREADS @infiles $outfiles[0] output_forward_unpaired.fq $outfiles[1] output_reverse_unpaired.fq  LEADING:28 TRAILING:28 SLIDINGWINDOW:4:15 MINLEN:50`;
	}
	if($nfiles == 1){
		`trimmomatic  SE -threads $THREADS @infiles @outfiles LEADING:28 TRAILING:28 SLIDINGWINDOW:4:15 MINLEN:50`;
	}
}
