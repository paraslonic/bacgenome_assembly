echo "running saet..."

THREADS=$1
if [ -z $THREADS ]; then
	echo "WARNING: THREADS was not specified. Using 1."
	THREADS=1
fi

saet=/data3/bio/biouser/tools/denovo2-saet3.0-velvet1.2.07/saet.3.0/saet

GLength=$(grep "GLENGTH" project.txt | sed 's/.\+= *//g')
if [ -z $GLength ]; then
	echo "GLENGTH cannot be found in project.txt"
	exit
fi

for f in reads/*.f*
do
        name=$(basename "$f")
        ext="${name##*.}"
        name="${name%.*}"
        $saet $f $GLength -numcores $THREADS -fixdir reads/saet
	echo "$saet $f $GLength -numcores $THREADS -fixdir reads/saet"
done

