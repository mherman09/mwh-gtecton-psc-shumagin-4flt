#!/bin/bash

function usage () {
    echo $0: NNODE NPROC 1>&2
    exit 1
}

# Read number of nodes and number of processors
NNODE="$1"
NPROC="$2"
if [ -z $NNODE ]
then
    echo "$0: must define number of nodes on command line" 1>&2
    usage
fi
if [ -z $NPROC ]
then
    echo "$0: must define number of processors on command line" 1>&2
    usage
fi
NTOT=`echo $NNODE $NPROC | awk '{print $1*$2}'`
shift; shift

# Other arguments
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        *) echo "$0: no option $1" 1>&2; exit 1;;
    esac
    shift
done


#####
#	PARTITION MESH
#####
${GTECTON_BIN_DIR}/partition -n tecin.dat.nps -e tecin.dat.elm -d 3 -p $NTOT -f

