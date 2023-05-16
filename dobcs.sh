#!/bin/bash

set -e

#####
#	GENERATE NODAL BOUNDARY CONDITION FILE
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
    echo $0: no geometry file named $GEO_FILE 1>&2
    exit 1
fi

# Optional arguments
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        *) echo "$0: no option $1" 1>&2; exit 1
    esac
    shift
done


#####
#	NODAL BOUNDARY CONDITION LOCATIONS
#####
# Fix back of upper plate (23), except for megathrust (41)
echo "$0: fixing back of upper plate except for megathrust" 1>&2
getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 23 -n 41 |\
    awk 'BEGIN{NONE=0;D=1;V=2;F=3}{printf("%12d%5d%5d%5d\n"),$1,D,D,0}' |\
    sort -nk1
# Displace downdip side (x=xmax) of subducting plate (except for megathrust)
echo "$0: displacing downdip side of subducting plate except for megathrust" 1>&2
getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 24 -n 41 |\
    awk 'BEGIN{NONE=0;D=1;V=2;F=3}{printf("%12d%5d%5d%5d\n"),$1,D,D,D}' |\
    sort -nk1
# Displace updip side (x=xmin) of subducting plate
echo "$0: displacing updip side of subducting plate except for megathrust" 1>&2
getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 25 |\
    awk 'BEGIN{NONE=0;D=1;V=2;F=3}{printf("%12d%5d%5d%5d\n"),$1,D,D,D}' |\
    sort -nk1
echo "end nodal bc location"

#####
#	NODAL BOUNDARY CONDITION MAGNITUDE
#####
# Front and back of subducting plate move along dip
DISP=1
echo "$0: setting displacement magnitudes" 1>&2
getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 24 -n 41 |\
    awk 'BEGIN{DX='"$DISP"';DY=0;DZ=0}{printf("%12d%14.6e%14.6e%14.6e\n"),$1,DX,DY,DZ}' |\
    sort -nk1
getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 25 |\
    awk 'BEGIN{DX='"$DISP"';DY=0;DZ=0}{printf("%12d%14.6e%14.6e%14.6e\n"),$1,DX,DY,DZ}' |\
    sort -nk1
echo "end nodal bc magnitude"

#####
#	NODAL WINKLER FORCES
#####
echo "end iwink"
echo "end wink"

#####
#	LOCAL DOF ROTATIONS
#####
AZ="0" # Rotation in the x-y plane about z-axis
DIP=`grep "dip =" $GEO_FILE | sed "s/;//" | awk '{print $3}'` # Rotation about new y-axis
# Front and back of subducting plate; orient x along dip
echo "$0: setting rotation angles" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -n 24 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 25 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
# Megathrust boundary same orientation as subducting plate
${GTECTON_BIN_DIR}/gmsh2tecton -n 26 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 27 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 30 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 31 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 41 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 42 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 43 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
${GTECTON_BIN_DIR}/gmsh2tecton -n 44 -i $MSH_FILE |\
    awk '{printf("%12d%14.6e%14.6e\n"),$1,'$AZ','$DIP'}' |\
    sort -nk1
echo "end Euler"

#####
#	CLEAN UP
#####
if [ -f junk ]; then rm junk; fi
