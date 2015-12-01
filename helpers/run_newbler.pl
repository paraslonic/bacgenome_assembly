
$THREADS = shift or $THREADS = 4;
$is_large = shift;
$is_large = ($is_large eq "large");

if ($is_large) {
 $dir_name = "assembly/newbler_large";
} else {
 $dir_name = "assembly/newbler";
}

if (!$is_large) {`bash helpers/runsaet.sh $THREADS`; }

@datas = `grep "data" project.txt`;

`mkdir -p assembly`;
`rm -rf $dir_name`; 
`newAssembly $dir_name`;
`cd $dir_name`;

foreach(@datas){
	chomp;
	/data\s+=\s+(.+)/;
	$str = $1;
	@outfiles = split(/\s/,$str);
	@infiles = @outfiles; 
	if (!$is_large) {map { $_ =~ s/reads/reads\/saet/g } @infiles; }
	$nfiles = scalar(@infiles);
	if($nfiles > 2) { print "--- more then 2 files in group! ---"; exit; }
	if($nfiles == 2) { 
		`cd $dir_name; addRun -lib libname -p ../../$infiles[0]`;
		`cd $dir_name; addRun -lib libname -p ../../$infiles[1]`;
	}
	if($nfiles == 1){
		`cd $dir_name; addRun ../../@infiles`;
	}
}

if ($is_large) {
 `cd $dir_name; runProject -cpu $THREADS -large`;
} else {
 `cd $dir_name; runProject -cpu $THREADS`;
}


