#!/bin/bash

function usage () {
    echo $0: NNODE NPROC 1>&2
    exit 1
}

# Read number of nodes and number of processors (should correspond to partitioning)
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
shift;shift

# Other arguments
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
MPI_BIN_DIR=/Users/mherman2-local/Research/openmpi-4.0.5/bin
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        --mpi-bin-dir=*) MPI_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        *) echo "$0: no option $1" 1>&2; exit 1
    esac
    shift
done


#####
#	RUN GTECTON
#####
WORKPATH=`pwd`
#          ASCII output---V   V---Write details of output to FEOUT.DAT
#mpirun -np $NPROC f3d_par as feout workpath=$WORKPATH partinfo=partition.info fein=TECIN.DAT fedsk=fedsk.par echo=2
${MPI_BIN_DIR}/mpirun -np $NTOT ${GTECTON_BIN_DIR}/f3d bi workpath=$WORKPATH partinfo=partition.info echo=2
${GTECTON_BIN_DIR}/mergefiles partinfo=partition.info bi
