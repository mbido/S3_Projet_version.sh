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
#test commentary
add(){
	cp "$1" ".version/$1.1"
	cp "$1" ".version/$1.latest"
}

if ! test -d .version;then
	echo 'Error! ".version" directory not found in current directory'
	echo 'Enter "./version.sh --help" for more information'
	exit 1;
elif test $# -eq 1 -a "$1" = "--help";then
	help
fi

add $1

