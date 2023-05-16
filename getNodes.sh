#!/bin/bash

#####
#       PARSE COMMAND LINE
#####
function usage() {
    echo "$0 MSH_FILE -l LBL -n LBL"
    exit 1
}

# Get mesh file name
MSH_FILE="$1"
shift

if [ "$MSH_FILE" == "" ]
then
    echo "$0: mesh file not defined" 1>&2
    usage
elif [ ! -f $MSH_FILE ]
then
    echo "$0: no mesh file named $MSH_FILE" 1>&2
    usage
fi

# Read labels and other arguments
LBL=""
NLBL=""
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        -l)shift;LBL="$1";;
        -n)shift;NLBL="$NLBL $1";;
        *)echo "$0: no option $1" 1>&2;usage
    esac
    shift
done

# Check that LBL, NLBL are entered correctly
LBL=`echo $LBL | awk '{if(/[A-Za-z]/){print "NO"}else{print $1}}'`
if [ -z "$LBL" ]
then
    echo "$0: -l LBL requires an entry" 1>&2
    usage
elif [ "$LBL" == "NO" ]
then
    echo "$0: -l LBL requires a numerical value" 1>&2
    usage
fi

NLBL=`echo $NLBL | awk '{if(/[A-Za-z]/){print "NO"}else{print $0}}'`
if [ "$NLBL" == "NO" ]
then
    echo "$0: -n NBL requires a numerical value" 1>&2
    usage
fi


######
#	GET LABELED NODES
######
# If removing nodes, create temporary file with nodes to remove
if [ -z "$NLBL" ]
then
    ${GTECTON_BIN_DIR}/gmsh2tecton -n $LBL -i $MSH_FILE -m
else
    START=1
    for i in $NLBL
    do
        if [ $START == 1 ]
        then
            ${GTECTON_BIN_DIR}/gmsh2tecton -n $i -i $MSH_FILE -m > junk
            START=0
        else
            ${GTECTON_BIN_DIR}/gmsh2tecton -n $i -i $MSH_FILE -m >> junk
        fi
    done
    sort -nuk1 junk > j; mv j junk
    NN=`wc junk | awk '{print $1}'`
	${GTECTON_BIN_DIR}/gmsh2tecton -n $LBL -i $MSH_FILE |\
		cat junk - |\
		awk '{
			if (NR<='"$NN"') {
				node[NR] = $1
			}
			else {
				p = 1
				for (i=1;i<='"$NN"';i++) {
					if ($1 == node[i]) {
						p = 0
					}
				}
				if (p == 1) {
					print $1
				}
			}
		}'
	rm junk
fi

