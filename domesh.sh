#!/bin/bash

#####
#	GENERATE (OPTIMIZED) MESH FROM GEOMETRY FILE
#####


#####
#	PARSE COMMAND LINE
#####
if [ $# -lt 2 ]
then
    echo Usage: $0 GEO_FILE MSH_FILE
    exit 1
fi
GEO_FILE="$1"
MSH_FILE="$2"
shift; shift

if [ ! -f $GEO_FILE ]
then
    echo Error: no geometry file named $GEO_FILE
    exit 1
fi

# Optional arguments
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) echo $1; GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
    esac
    shift
done
echo GTECTON_BIN_DIR=$GTECTON_BIN_DIR


#####
#	GENERATE TETRAHEDRAL MESH
#####
gmsh -3 -format msh22 ${GEO_FILE} -o ${MSH_FILE}


#####
#	GENERATE GTECTON FORMATTED FILES
#####
${GTECTON_BIN_DIR}/gmsh2tecton -c -i ${MSH_FILE} -o tecin.dat.nps
${GTECTON_BIN_DIR}/gmsh2tecton -e -i ${MSH_FILE} -o tecin.dat.elm
