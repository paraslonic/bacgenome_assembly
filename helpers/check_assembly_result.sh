#!/bin/bash

assembler=$1

if [ "$assembler" != "m" ] && [ "$assembler" != "n" ] && [ "$assembler" != "s" ]
then
	echo "Can't found parameter, defining the assembler.\nParameter must be one of:\n 'm': Mira\n 'n': Newbler\n 's': Spades"
	exit 1
fi

if [ "$assembler" = "m" ]
then
	filename="assembly/mira/mira_d_results/mira_out.unpadded.fasta"
	send_filename="tmp/runmira.sh.o tmp/runmira.sh.e"
	assembler_name="Mira"
fi

if [ "$assembler" = "n" ]
then
	filename="assembly/newbler/assembly/454LargeContigs.fna"
	send_filename="tmp/runnewbler.sh.o tmp/runnewbler.sh.e"
	assembler_name="Newbler"
fi

if [ "$assembler" = "s" ]
then
	filename="assembly/spades/contigs.fasta"
	send_filename="tmp/runspades.sh.o tmp/runspades.sh.e"
	assembler_name="Spades"
fi

filename_receivers="python/receivers_tmp.ini"

if [ ! -f $filename ]
then
	while read line; do
	    python python/run_send_mail.py -s "Ошибка при сборке $assembler_name" -f $send_filename -r $line
	done < $filename_receivers
	exit 1
fi

exit 0
