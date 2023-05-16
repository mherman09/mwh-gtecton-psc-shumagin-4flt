#!/bin/bash

#####
#	TITLE OF MODEL
#####
TITLE="Pseudo-coupling: Shumagin Gap region - 2020-2021 EQ sequence"

#####
#	NODE AND ELEMENT FILES
#####
NPS_FILE="tecin.dat.nps"
ELM_FILE="tecin.dat.elm"
NUMNP=`wc $NPS_FILE | awk '{print $1-1}'`
NUMEL=`wc $ELM_FILE | awk '{print $1-1}'`
NPS_FILE="tecin.dat.partf.nps"
ELM_FILE="tecin.dat.partf.elm"

#####
#	GTECTON FLAGS
#####
MODE="2"     # Solver switch: 2: mechanical solution; 5: thermal solution; 6: mech + therm solution
NINTG="1"    # Number of time step groups (for single time step elastic problem, can use 0)
NMPRT="2"    # Number of mechanical solution outputs
MAXIT="1"    # Max number of iterations between stiffness matrix reforms
NLINK="0"    # Number of linked nodes
ICVIS="0"    # Viscosity update switch
ISTART="0"   # Restart switch
NELAST="0"   # ITIME=0 load switch
NPRMAT="0"   # Number of matrix diagonal outputs
IVELOOUT="0" # Velocity output switch
CYCLIC="0"

IMPRINT="9 19"  # Times of output (if NMPRT!=0)
IMATPR=""    # Times of matrix diagonal output (if NPRMAT!=0)

GRAV="0 0 -9.8" # Gravity

#####
#	TIME STEP GROUP PARAMETERS
#####
MAXSTP="   19   11" # Number of time steps in each group
DELT="    0.0    0" # Time step size of each group
UNIT="    sec  sec" # Time step units (sec, msec, year, Ma)
ALPHA="   0.5  0.5" # Alpha parameters

#####
#	DEFORMATION SWITCHES
#####
IOPT="0"    # 0=plane strain; 1=plane stress
IPOINT="1"  # Integration rule for forces
LGDEF="1"   # Large deformation update
IRESDU="2"  # Residual forces update
IGRAV="0"   # Gravity switch
IVLIM="0"   # Viscosity minimum switch
INCOMP="0"  # Incompatibility mode
NOCOMPR="0" # Incompressibility
NSED="0"    # Sediment transport loads
ISHELL="0"  # Spherical geometry switch

#####
#	ELEMENT PARAMETERS
#####
NUMAT="2" # Number of material types
NSURF="0" # Number of surface nodal points
#     MAT_NO   YNG_MOD  POISSON    VISC   POWER  DENSITY  THICK
MAT='      1      1e11     0.25  1.0e30       1        1      1
           2      1e11     0.25  1.0e30       1        1      1'

#####
#	NODE BOUNDARY CONDITION FILES
#####
NBC_FILE="tecin.dat.bcs"
if [ ! -f $NBC_FILE ]
then
    echo "!! Error: no file $NBC_FILE" 1>&2
    exit 1
fi

#####
#	ELEMENT BOUNDARY CONDITION FILES
#####
PRS_FILE=""
STS_FILE=""
WNK_FILE=""
SLP_FILE="tecin.dat.slp"
PAR_FILE=""
SPL_FILE=""
PRE_FILE=""
TRP_FILE=""

#####
#	ELEMENT BOUNDARY CONDITIONS
#####
NUM=""
for i in "$PRS_FILE" "$STS_FILE" "$WNK_FILE" "$SLP_FILE" \
         "$PAR_FILE" "$SPL_FILE" "$PRE_FILE" "$TRP_FILE"
do
    if [ -z $i ]
    then
        NUM="$NUM  0"
    else
        N=`awk '{if($1!="end"){print 1}else{exit}}' $i | wc | awk '{print $1}'`
        NUM="$NUM $N"
    fi
done

#######################################################################################################
#######################################################################################################
#######################################################################################################

echo "$TITLE" | awk '{printf("%-80s\n"),$0}'
echo "$NUMNP $NUMEL $NUMAT" | awk '{printf("%12d%12d%12d\n"),$1,$2,$3}'
echo "$MODE $NINTG $NMPRT $MAXIT $NLINK $ICVIS $ISTART $NELAST $NPRMAT $IVELOOUT $CYCLIC" |\
    awk '{printf("%5d%5d%5d%5d%5d%5d%5d%5d%5d%5d%5d\n"),$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'
echo "$NMPRT $IMPRINT" | awk '{if($1>0){for(i=1;i<=$1;i++){printf("%5d"),$(i+1)};printf("\n")}}'
echo "$NPRMAT $IMATPR" | awk '{if($1>0){for(i=1;i<=$1;i++){printf("%5d"),$(i+1)};printf("\n")}}'
echo ".so $NPS_FILE"
echo ".so $ELM_FILE"
echo ".so $NBC_FILE"
NR=`echo $NINTG | awk '{if($1<1){print 1}else{print $1}}'`
echo "$NR $MAXSTP" | awk '{for(i=1;i<=$1;i++){printf("%5d"),$(i+1)};printf("\n")}'
echo "$NR $DELT" | awk '{for(i=1;i<=$1;i++){
                           if ($(i+1)<10) {printf("%5.3f"),$(i+1)}
                           else if ($(i+1)<100) {printf("%5.2f"),$(i+1)}
                           else if ($(i+1)<1000) {printf("%5.1f"),$(i+1)}
                           else if ($(i+1)<10000) {printf("%5.0f"),$(i+1)}
                           else {printf("%5.0f"),$(i+1)}
                   };printf("\n")}'
echo "$NR $UNIT" | awk '{for(i=1;i<=$1;i++){printf("%5s"),$(i+1)};printf("\n")}'
echo "$NR $ALPHA" | awk '{for(i=1;i<=$1;i++){printf("%5.1f"),$(i+1)};printf("\n")}'
echo "$IOPT $IPOINT $LGDEF $IRESDU $IGRAV $IVLIM $INCOMP $NOCOMPR $NSED $ISHELL" |\
    awk '{printf("%5d%5d%5d%5d%5d%5d%5d%5d%5d%5d\n"),$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}'
echo 0 | awk '{printf("%5d\n"),$1}'
echo "$NUM" | awk '{printf("%12d%12d%12d%12d%12d%12d%12d%12d\n"),$1,$2,$3,$4,$5,$6,$7,$8}'
echo "$MAT" | awk '{printf("%12d%14.6e%14.6e%14.6e%14.6e%14.6e%14.6e\n"),$1,$2,$3,$4,$5,$6,$7}'
echo "end material properties"
echo "$GRAV" | awk '{printf("%14.2f%14.2f%14.2f\n"),$1,$2,$3}'
for i in "$PRS_FILE" "$STS_FILE" "$WNK_FILE" "$SPL_FILE" "$SLP_FILE" "$PAR_FILE" "$PRE_FILE" "$TRP_FILE"
do
    if [ ! -z $i ]
    then
        echo ".so $i"
    fi
done
