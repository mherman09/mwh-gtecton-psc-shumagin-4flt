#!/bin/bash

#####
#	PARSE COMMAND LINE
#####
function usage () {
    echo "$0 MSH_FILE"
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

# Read other arguments
GTECTON_BIN_DIR=/Users/mherman2-local/Research/gtecton/build2
while [ "$1" != "" ]
do
    case $1 in
        --gtecton-bin-dir=*) GTECTON_BIN_DIR=$(echo $1 | awk -F= '{print $2}');;
        *) echo "$0: no option $1" 1>&2;usage;;
    esac
    shift
done


#####
#	COUNT NUMBER OF NON-TETRAHEDRAL ELEMENTS
#####
# NOTHR=`getNonTet.sh ${MSH_FILE}`
NOTHR=0

#####
#	EXTRACT NODE-ELEMENT PAIRS ON MEGATHRUST FOR SLIPPERY BCS
#####
# 0: No differential Winkler forces
# >0: Winkler forces applied at step (STEP-1)
# <0: Winkler forces applied until step ABS(STEP)
LOCK_STEP="0"
UNLK_STEP_27="-10" # Earthquake in central Chignik patch
# UNLK_STEP_27="1" # Keep central Chignik patch locked
UNLK_STEP_30=0 # Unlocked Shumagin Gap
# UNLK_STEP_30=1 # Locked Shumagin Gap
UNLK_STEP_31="-100" # Locked eastern 1938 asperity
UNLK_STEP_32=0 # Unlocked updip asperity
# UNLK_STEP_32=-100 # Locked updip asperity
# UNLK_STEP_32=10 # Updip only locked coseismically
# UNLK_STEP_32=-10 # Updip ruptured coseismically
MGT_WNK="1e20"
FLT_WNK="1e20"

# Save element #, node #, z-component, step, winkler constant
if [ -f junk_slipry.tmp ]; then rm junk_slipry.tmp; fi
echo "$0: Selecting non-asperity nodes (26)" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -f 26 -i $MSH_FILE |\
    awk '{print $1,$2,$5,'"$LOCK_STEP"','"$MGT_WNK"'}' >> junk_slipry.tmp
echo "$0: Selecting asperity nodes (27)" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -f 27 -i $MSH_FILE |\
    awk '{print $1,$2,$5,'"$UNLK_STEP_27"','"$FLT_WNK"'}' >> junk_slipry.tmp
echo "$0: Selecting asperity nodes (30)" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -f 30 -i $MSH_FILE |\
    awk '{print $1,$2,$5,'"$UNLK_STEP_30"','"$FLT_WNK"'}' >> junk_slipry.tmp

# eastern 1938 asperity
echo "$0: Selecting asperity nodes (31)" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -f 31 -i $MSH_FILE |\
    awk '{print $1,$2,$5,'"$UNLK_STEP_31"','"$FLT_WNK"'}' >> junk_slipry.tmp
#${GTECTON_BIN_DIR}/gmsh2tecton -f 31 -i $MSH_FILE |\
#    awk '{print $1,$2,$5,10,'"$FLT_WNK"'}' >> junk_slipry.tmp

# updip 1938 asperity
echo "$0: Selecting asperity nodes (32)" 1>&2
${GTECTON_BIN_DIR}/gmsh2tecton -f 32 -i $MSH_FILE |\
    awk '{print $1,$2,$5,'"$UNLK_STEP_32"','"$FLT_WNK"'}' >> junk_slipry.tmp

#####
#	REMOVE NODE-ELEMENT DOUBLES
#####
#cat junk_slipry.tmp | rmdoubles_mwh > junk_slipry_2.tmp
cp junk_slipry.tmp junk_slipry_2.tmp

#####
#	GENERATE GTECTON SLIPPERY NODE BC FILE
#####
awk 'BEGIN{dn='$NOTHR';WX=1;WY=1;WZ=0;DFX=0;DFY=0;DFZ=0}
{
  if ($3 < 0) {
    printf("%12d%12d%5d%5d%5d%14.6e%14.6e%14.6e\n"),$1-dn,$2,WX,WY,WZ,DFX,DFY,DFZ
  } else {
    printf("%12d%12d%5d%5d%5d%14.6e%14.6e%14.6e\n"),$1-dn,$2,(-1)*WX,(-1)*WY,WZ,DFX,DFY,DFZ
  }
}' junk_slipry_2.tmp

echo "end slippery node locations"

#####
#	SLIPPERY NODE DIFFERENTIAL WINKLER FORCES
#####
awk '{printf("%12d%5d%5d%5d\n"),$2,$4,$4,0}' junk_slipry_2.tmp
echo "end differential winkler step"

awk '{if($4!=0)printf("%12d%14.6e%14.6e%14.6e\n"),$2,$5,$5,0}' junk_slipry_2.tmp
echo "end differential winkler magnitude"

#####
#	CLEAN UP
#####
rm junk*tmp
