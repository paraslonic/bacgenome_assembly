$THREADS = shift or $THREADS = 15;

@datas = `grep "data" project.txt`;

`rm -r assembly/spades`;

$run = "spades ";

foreach(@datas){
	chomp;
	/data\s+=\s+(.+)/;
	$str = $1;
	@infiles = split(/\s/,$str);
	$nfiles = scalar(@infiles);
	if($nfiles > 2) { print "--- more then 2 files in group! ---"; exit; }
	if($nfiles == 2) { 
		$run .= "-1 ".$infiles[0]." -2 ".$infiles[1]." ";
	}
	if($nfiles == 1){
		$run .= "-s ".$infiles[0]." ";
	}
}
$run .= " -t $THREADS -o assembly/spades";
print `$run`;
