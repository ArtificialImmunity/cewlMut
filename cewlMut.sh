#!/bin/bash

# This script uses CeWL, John, and RSMangler to generate an extensive wordlist
# and can be used to test the password strength of your websites passwords 
# i.e. if it appears in this list, it would be worth changing it.

#			Copyright (C) 2015  Jordan Bruce

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#   For a copy of the GNU General Public License, please see
#   <http://www.gnu.org/licenses/>.

#Defaults
DEPTH=2
MINLEN=6
MAXLEN=12
OUTPUT=CeWLMutOutput

print_usage() {
	echo ""
	echo "CeWLMut - A tool to generate mutated CeWL wordlists"
	echo ""
	echo "Usage: cewlMut [OPTION] ... URL
	-d: depth of CeWL spider, default $DEPTH
	-m: minimum word length, default $MINLEN
	-x: maximum word length, default $MAXLEN
	-o: specify the name of the output directory, default $OUTPUT"
	exit
}

#Parse the options
while getopts 'd:m:x:o:' opt ; do
	case $opt in
		d) DEPTH=$OPTARG ;;
		m) MINLEN=$OPTARG ;;
		x) MAXLEN=$OPTARG ;;
		o) OUTPUT=$OPTARG ;;
	esac
done
#skip over the processed options
shift $((OPTIND-1))

if [ -z "$1" ]; then
    echo "You must specify a URL!"
    print_usage
    exit
fi

#check if user has cewl, john, and, rsmangler
dependencies=(cewl john rsmangler)
DEPENDENCIESCHECK=0

for dependency in ${dependencies[*]}
do
	command -v $dependency >/dev/null 2>&1 || { echo "$dependency is required but does not exist in \$PATH." >&2; DEPENDENCIESCHECK=1; }
done

if [ $DEPENDENCIESCHECK -eq 1 ]
then
	echo "[-] Exiting"
	exit
fi

#Files
CEWLRAWFILE=$OUTPUT/rawwords.lst
CEWLBASEFILE=$OUTPUT/basewords.lst
CEWLORDEREDBASE=$OUTPUT/orderedbasewords.lst
CEWLMUTBASEFILE=$OUTPUT/mutbasewords.lst
CEWLMUTFILE=$OUTPUT/wordlist.lst

#---Script Starts Interacting---#

#Arguments
URL=$1

#Check if URL is vaild by attempting to curl the head
curl -s --head $URL | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
if [ $? -eq 1 ]
then
	echo "Invaild URL"
	echo "[-] Exiting"
	exit
fi

if [ -d $OUTPUT ]
then
	echo "$OUTPUT already exists as a directory"
	echo "[-] Exiting"
	exit
else
	mkdir $OUTPUT
fi

#Start CeWL on inputted URL 
echo "[+] Using CeWL to generate base set of words from $URL"
echo "... this may take a minute ..."
cewl -d $DEPTH -m $MINLEN -w $CEWLRAWFILE $URL > /dev/null
echo "[+] CeWL finished"

#Use awk to delete and words over max limit
echo "[+] Triming max lenght words"
awk "length <= $MAXLEN" $CEWLRAWFILE > $CEWLBASEFILE

#Make sure the list is unique, then sort
echo "[+] Unique sorting base words"
sort -uf $CEWLBASEFILE -o $CEWLORDEREDBASE

#Use rsmangler to mutate base words with caps and leet speak
echo "[+] Using RSMangler to mutate base words with caps and leet speak"
rsmangler -f $CEWLORDEREDBASE -pdseiay --punctuation --pna --pnb --na --nb --force > $CEWLMUTBASEFILE

#Use john rules to mutate the modified base word list
echo "[+] Using John to mutate modified base words"
john --wordlist=$CEWLMUTBASEFILE --rules --stdout > $CEWLMUTFILE

#Use rsmangler rules to mutate the base word list from CeWL
echo "[+] Using RSMangler to mutate base words with caps and leet speak"
rsmangler -f $CEWLMUTBASEFILE -ptTculseia --punctuation --pna --pnb --na --nb --force >> $CEWLMUTFILE

#Delete unwanted files and only leave the final wordlist
#echo "[+] Cleaning up"
#rm $CEWLRAWFILE $CEWLBASEFILE $CEWLORDEREDBASE $CEWLMUTBASEFILE 

echo "[+] Done"
