#!/bin/dash

help(){
	echo 'Usage:
\t./version.sh --help
\t./version.sh <command> FILE [OPTION]
\t\twhere <command> can be: add amend checkout|co commit|ci diff log reset rm

./version.sh add FILE MESSAGE
\tAdd FILE under versioning with the initial log message MESSAGE

./version.sh commit|ci FILE MESSAGE
\tCommit a new version of FILE with the log message MESSAGE

./version.sh amend FILE MESSAGE
\tModify the last registered version of FILE, or (inclusive) its log message

./version.sh checkout|co FILE [NUMBER]
\tRestore FILE in the version NUMBER indicated, or in the
\tlatest version if there is no number passed in argument

./version.sh diff FILE
\tDisplays the difference between FILE and the last committed version

./version.sh log FILE
\tDisplays the logs of the versions already committed

./version.sh reset FILE NUMBER
\tRestores FILE in the version NUMBER indicated and
\tdeletes the versions of number strictly superior to NUMBER

./version.sh rm FILE
\tDeletes all versions of a file under versioning'
}
add(){
	if test $# -ne 1;then
		echo "Error! wrong number of arguments. 1 argument expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
	elif ! test -f $1 -a -r $1;then
		echo "Error! $1 is not a regular file or read permission is not granted."
		echo 'Enter "./version.sh --help" for more information.'
	elif ! test -d .version;then
		mkdir .version
	fi
	cp "$1" ".version/$1.1"
	cp "$1" ".version/$1.latest"
}

rm(){
	if test $# -ne 1;then
		# this test needs to be remove at the end !
		echo "Error! wrong number of arguments. 1 argument expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		return 1; #using return because it would be a dev error and so no sys-call required
	elif ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1;
	elif ! ls ".version/$1.1" >/dev/null 2>&1;then
		echo "Error! unable to find $1 file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1;
	fi

	echo -n "Are you sure you want to delete '$1' from versioning ? "
	read RESP
	RESP=$(echo $RESP | tr '[:upper:]' '[:lower:]')
	if test "$RESP" = "yes" -o "$RESP" = "y" -o;then
		/bin/rm ".version/$1."*
		echo "'$1' is not under versioning anymore."
	else
		echo "Nothing done."
	fi
}


if test $# -eq 1 -a "$1" = "--help";then
	help
	exit 0;
fi
add $1
rm $1