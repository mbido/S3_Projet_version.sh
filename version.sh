#!/bin/dash

# functions for error's managment


# inform that a wrong number of arguments whas given 
# then exit
# 	$1 -> number of arguments expected
# 	$2 -> number of arguments given
nbArgError(){
	echo "Error! wrong number of arguments. $1 argument expected but $2 where given"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
}

# inform that the file given as an argument is not a regular file or
# it's read permission is not granted 
# then exit
# 	$1 -> file name
notRegularFileError(){
	echo "Error! $1 is not a regular file or read permission is not granted."
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
}

# inform that a commentary that needed to be not empty is in fact empty 
# then exit
emptyCommentError(){
	echo "Error! commentary is empty"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
}

# inform that the commentary given as an argument is on multiple ones instead of one
# then exit
# 	$1 -> string
notInlineCommentError(){
	echo "Error! $1 is not a one line commentary"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
}


# inform that the '.version' directory do not exist
noVersioningDirectoryError(){
	echo "Error! '.version' directory was not found"
	exit 1
}


# inform that the file given as an argument is not in the versioning directory (.version)
# 	$1 -> file that should have been in versioning
noFileInVersioningError(){
	echo "Error! unable to find '$1' file in versioning"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
}

# main functions

# display on its standard output the man page of the version.sh command
help() {
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


# start a versioning on a file given as an argument and save a comment also given in a log file
#
# the file musn't be in the versioning directory (.version)
# the comment need to not be empty and on one line
#
# 	$1 -> the file in question
# 	$2 -> the comment in question
add() {
	FILE=${1##*/}
	if ! test -f $1 -a -r $1; then #EXIT
		notRegularFileError $1
	elif ! test -d .version; then #EXIT
		mkdir .version
	elif ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		echo "Nothing was done : '$1' file already present in versioning"
		exit 0
	fi
	date=$(date -R)
	COMMENT=$(echo $2 | sed -E 's/\t//g' | sed -E 's/^ *//' | sed -E 's/ *$//')
	if ! test -n "$COMMENT"; then #EXIT
		emptyCommentError
	elif test $(echo -n "$2" | wc -l) -eq 1; then #EXIT
		notInlineCommentError $2
	elif ! test -f ".version/$FILE.log"; then
		COMMENT="$date '$COMMENT'"
		echo "$COMMENT" >".version/$FILE.log"
	fi
	cp "$1" ".version/$FILE.1"
	cp "$1" ".version/$FILE.latest"
}

# remove a file from the versioning directory (.version)
#
# the file need to exist in versioning
#
#	$1 -> the file in question
rmInternal() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	fi
	echo -n "Are you sure you want to delete '$FILE' from versioning ? (yes/no) "
	read RESP
	RESP=$(echo $RESP | tr '[:upper:]' '[:lower:]')
	if test "$RESP" = "yes" -o "$RESP" = "y"; then
		rm ".version/$FILE."*
		echo "'$FILE' is not under versioning anymore."
		rmdir .version 2>/dev/null
	else
		echo "Nothing done."
	fi
}

# commit a new version of a file with a comment or do nothing if the file has not changed from
# the latest saved version
#
# the file need to exist in versioning
# the comment need to not be empty and on one line
#
# 	$1 -> the file in question
# 	$2 -> the comment in question
commit() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	elif cmp ".version/$FILE.latest" "$1" >/dev/null 2>&1; then
		echo "Nothing done : '$FILE' already updated in versioning"
		exit 0
	fi
	date=$(date -R)
	COMMENT=$(echo $2 | sed -E 's/\t//g' | sed -E 's/^ *//' | sed -E 's/ *$//')
	if ! test -n "$COMMENT"; then #EXIT
		emptyCommentError
	elif test $(echo -n "$2" | wc -l) -eq 1; then #EXIT
		notInlineCommentError $2
	else
		COMMENT="$date '$COMMENT'"
		echo "$COMMENT" >> ".version/$FILE.log"
	fi

	#getting the NEW version number :
	VERSION=$(($(ls ".version/$FILE."* | wc -l) - 1))

	diff -u ".version/$FILE.latest" "$1" >".version/$FILE.$VERSION"
	cp "$1" ".version/$FILE.latest"
	echo "Committed a new version : $VERSION"
}

# display on its standard output the difference between the file given as an argument and its latest version in versioning
#
# the file need to exist in versioning
#
# 	$1 -> the file in question
diffInternal() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	fi

	diff -u ".version/$FILE.latest" "$1"
}

# put the file given as an argument to specific version
# do not remove any version from versioning
#
# the file need to exist in versioning
# the version number must be less or equal than the latest version number
#
# 	$1 -> the file in question
# 	$2 -> the version in question
checkout() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	elif test $# -eq 1; then
		cp ".version/$FILE.latest" "$1"
		echo "Checked out to the latest version"
	else
		#getting the version number :
		VERSION=$(($(ls ".version/$FILE."* | wc -l) - 2))

		if test $2 -gt $VERSION; then #EXIT
			noFileInVersioningError $2
		fi

		cp ".version/$FILE.1" "$1"
		VAR=2
		while test $VAR -le $2; do
			patch -u "$1" ".version/$FILE.$VAR" >/dev/null
			VAR=$((VAR + 1))
		done
		echo "Checked out version : $2"
	fi
}

# display  on its standard output the log file of the file given as an argument
#
# the file need to exist in versioning
#
# 	$1 -> the file in question
log() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.log" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	fi
	awk '{print NR" : "$0}' .version/$FILE.log
}

# reset the file given as an argument to a specific version (similar to checkout) and remove every more recent versions
#
# the file need to exist in versioning
# the version number must be less or equal than the latest version number
#
# 	$1 -> the file in question
# 	$2 -> the version in question
reset() {
	FILE=${1##*/}
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	fi

	# getting the version number :
	VERSION=$(($(ls ".version/$FILE."* | wc -l) - 2))

	if test $2 -gt $VERSION; then #EXIT
		noFileInVersioningError $2

	elif test $2 -eq $VERSION; then
		checkout $1
		exit 0
	else
		echo -n "Are you sure you want to reset ’$1’ to version $2 ? (yes/no) "
		read RESP

		#formating the answer
		RESP=$(echo $RESP | tr '[:upper:]' '[:lower:]')

		if test "$RESP" = "yes" -o "$RESP" = "y"; then
			# first we remove the more recent versions in the versioning than the one we want
			VAR=$2
			VAR=$((VAR + 1))
			while test $VAR -le $VERSION; do
				rm ".version/$FILE.$VAR"
				VAR=$((VAR + 1))
			done

			# then we checkout the corresponding version
			checkout $1 $2 >/dev/null

			# finaly we update the .latest from the versioning
			cp "$1" ".version/$FILE.latest"
			echo "Reset to version: $2"
		else
			echo "Nothing done."
		fi
	fi
}

# alows to modifie the latest commit by changing its comment in the log file or (inclusive) the version itself
#
# the file need to exist in versioning
# the comment need to not be empty and on one line
#
# 	$1 -> the file in question
# 	$2 -> the comment in question
amend() {
	FILE=${1##*/}
	TRY=0
	if ! test -d .version; then #EXIT
		noVersioningDirectoryError
	elif ! ls ".version/$FILE.1" >/dev/null 2>&1; then #EXIT
		noFileInVersioningError $FILE
	fi
	COMMENT="$2"
	# getting the number of the latest version of the file and comment
	latest_version=$(ls -1 ".version/$FILE."* | sort -n | tail -3 | head -n 1)
	latest_comment=$(cat .version/$FILE.log | tail -n 1 | grep -o "'[^']*'" | sed "s/'//g")
	latest_version_number=$(basename "$latest_version" | cut -d '.' -f 3)
	
	# cmp between the latest_file and the file to amend
	if ! cmp -s "$1" "$latest_version"; then
		cp "$1" "$latest_version"
		cp "$1" ".version/$FILE.latest"
		TRY=1
	fi
	if test "$2" != "$latest_comment"; then
		date=$(date -R)
		NEW_COMMENT=$(echo $2 | sed -E 's/\t//g' | sed -E 's/^ *//' | sed -E 's/ *$//')
		if test $(echo "$NEW_COMMENT" | wc -l) -gt 1; then #EXIT
			notInlineCommentError $NEW_COMMENT
		elif ! test -n "$NEW_COMMENT"; then
			emptyCommentError
		fi
		sed -i '$ d' .version/$FILE.log
		NEW_COMMENT="$date '$NEW_COMMENT'"
		echo "$NEW_COMMENT" >>.version/$FILE.log
		echo "Latest version amended : $latest_version_number"
		TRY=1
	fi
	if test $TRY -eq 0;then
		echo "no change to amend"
	fi

	# cmp the latest_comment and the comment to amend

}



# every main function's call

if test $# -eq 0; then
	echo "Error! no argument was given"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
fi

case "$1" in
"--help" | "--h")
	if test $# -ne 1; then #EXIT
		nbArgError 1 $#
	fi
	help
	;;
"add")
	if test $# -ne 3; then #EXIT
		nbArgError 3 $#
	fi
	add $2 "$3"
	;;
"rm")
	if test $# -ne 2; then #EXIT
		nbArgError 2 $#
	fi
	rmInternal $2
	;;
"commit" | "ci")
	if test $# -ne 3; then #EXIT
		nbArgError 3 $#
	fi
	commit $2 "$3"
	;;
"diff")
	if test $# -ne 2; then #EXIT
		nbArgError 2 $#
	fi
	diffInternal $2
	;;
"checkout" | "co")
	if test $# -eq 2; then
		checkout $2
	elif test $# -eq 3; then
		checkout $2 $3
	else
		echo "Error! wrong number of arguments. 2 or 3 arguments expected but $# where given"
		echo 'Enter "./version.sh --help" for more information.'
		exit 1
	fi
	;;
"reset")
	if test $# -ne 3; then #EXIT
		nbArgError 3 $#
	fi
	reset $2 $3
	;;

"log")
	if test $# -ne 2; then #EXIT
		nbArgError 2 $#
	fi
	log $2
	;;
"amend")
	if test $# -ne 3; then #EXIT
		nbArgError 3 $#
	fi
	amend $2 "$3"
	;;
*)
	echo "Error! '$1' is not a valid command"
	echo 'Enter "./version.sh --help" for more information.'
	exit 1
	;;

esac
