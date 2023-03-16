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
	FILE=${1##*/}
	if ! test -f $1 -a -r $1;then
		echo "Error! $1 is not a regular file or read permission is not granted."
		echo 'Enter "./version.sh --help" for more information.'
	elif ! test -d .version;then
		mkdir .version
	fi
	COMMENT=$(sed -E 's/^ *//' | sed -E 's/ *$//') 
	if test -n $COMMENT; then
		echo "Error! $2 is empty"
		echo 'Enter "./version.sh --help" for more information.'
	elif echo "$str" | grep -q '\n'; then
		echo "Error! $2 is not a one line commentary"
		echo 'Enter "./version.sh --help" for more information.'
	elif ! test -f ".version/$FILE.log"; then
		cp "$COMMENT" ".version/$FILE.log"
		
	fi

	
	
	cp "$1" ".version/$FILE.1"
	cp "$1" ".version/$FILE.latest"

}

rm(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	echo -n "Are you sure you want to delete '$FILE' from versioning ? "
	read RESP
	RESP=$(echo $RESP | tr '[:upper:]' '[:lower:]')
	if test "$RESP" = "yes" -o "$RESP" = "y" -o;then
		/bin/rm ".version/$FILE."*
		echo "'$FILE' is not under versioning anymore."
		rmdir .version 2>/dev/null
	else
		echo "Nothing done."
	fi
}

commit(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	elif cmp ".version/$FILE.latest" "$1" >/dev/null 2>&1;then
		echo "Nothing done : '$FILE' already updated in versioning"
		exit 0
	fi
	
	#getting the version number :
	VERSION=$(ls ".version/$FILE."* | wc -l)
	
	/bin/diff -u ".version/$FILE.latest" "$1" > ".version/$FILE.$VERSION"
	cp "$1" ".version/$FILE.latest"
	echo "Committed a new version : $VERSION"
}

diff(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	
	/bin/diff -u ".version/$FILE.latest" "$1"
}

checkout(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versionings"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	elif test $# -eq 1;then
		cp ".version/$FILE.latest" "$1"
		echo "Checked out to the latest version"
	else
		#getting the version number :
		VERSION=$(ls ".version/$FILE."* | wc -l)
		
		if test $2 -ge $VERSION;then
			echo "Error! there is no version $2 in versioning"
			echo 'Enter "./version.sh --help" for more information.'
			exit 1;
		fi  
		
		cp ".version/$FILE.1" "$1"
		VAR=2
		while test $VAR -le $2;do
			patch -u "$1" ".version/$FILE.$VAR" >/dev/null
			VAR=$((VAR + 1))
		done
		echo "Checked out version : $2"
	fi
}

log(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.log" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi

	
}



reset(){
	FILE=${1##*/}
	if ! test -d .version;then
		echo "Error! '.version' directory was not found"
		exit 1
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1;then
		echo "Error! unable to find '$FILE' file in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	
	# getting the version number :
	VERSION=$(ls ".version/$FILE."* | wc -l)
	
	if test $2 -ge $VERSION;then
		echo "Error! there is no version $2 in versioning"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1;
	fi
	
	# first we checkout the corresponding version
	checkout $1 $2 >/dev/null
	
	# then we remove the most recent versions in the versioning 
	VAR=$2
	while test $VAR -lt $VERSION;do
		/bin/rm ".version/$FILE.$VAR"
		VAR=$((VAR + 1))
	done
	
	# finaly we update the .latest from the versioning
	cp "$1" ".version/$FILE.latest" 
}







if test $# -eq 0;then
	echo "Error! no argument was given"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1;
fi

case "$1" in
	"--help|--h")
	if test $# -ne 1;then
		echo "Error! wrong number of arguments. 1 argument expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	help
	;;
	"add")
	if test $# -ne 3;then
		echo "Error! wrong number of arguments. 3 arguments expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	add $2 $3
	;;
	"rm")
	if test $# -ne 2;then
		echo "Error! wrong number of arguments. 2 argument expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	rm $2
	;;
	"commit"|"ci")
	if test $# -ne 3;then
		echo "Error! wrong number of arguments. 3 arguments expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	commit $2 $3
	;;
	"diff")
	if test $# -ne 2;then
		echo "Error! wrong number of arguments. 2 argument expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	diff $2
	;;
	"checkout"|"co")
	if test $# -eq 2;then
		checkout $2
	elif test $# -eq 3;then
		checkout $2 $3
	else
		echo "Error! wrong number of arguments. 2 or 3 arguments expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	;;
	"reset")
	if test $# -ne 3;then
		echo "Error! wrong number of arguments. 3 arguments expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	reset $2 $3
	;;
	*)
	echo "Error! '$1' is not a valid command"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
	;;
esac







