#!/bin/bash

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


# Read GTECTON input and output files
cat > extract.s << EOF
femi
femo FEDSK.DAT
conn conn.dat
readmesh subduction.msh
set it 9
set tag 26
set tag 27
set tag 30
set tag 31
set tag 32
set tag 44
di flt_slip.dat slippery
set it 19
di flt_slip_eq.dat slippery
EOF

## Slippery displacements on plate interface
#getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 26  > j.tmp
#getNodes.sh ${MSH_FILE} --gtecton-bin-dir=${GTECTON_BIN_DIR} -l 27 >> j.tmp
#sort -nuk1 j.tmp |\
#    awk '{
#        print "di flt_slip_"$1".tmp slippery"
#    }' >> extract.s

echo "q!" >> extract.s


${GTECTON_BIN_DIR}/plt3d extract.s
