#!/bin/bash

GEO_FILE=`grep "GEO_FILE =" Makefile | awk '{print $3}'`
MSH_FILE=`grep "MSH_FILE =" Makefile | awk '{print $3}'`

#####
#	PREPARE VARIABLES AND FILES
#####
# Fault geometry
DIP=`grep "dip =" $GEO_FILE | sed "s/;//" | awk '{print $3}'`
COSD=`echo $DIP | awk '{print cos($1*0.01745)}'`
SIND=`echo $DIP | awk '{print sin($1*0.01745)}'`
FLT_WID=`grep "flt_wid =" $GEO_FILE | awk '{print $3}' | sed -e "s/e3;//"`
FLT_LEN=`grep "flt_len =" $GEO_FILE | awk '{print $3}' | sed -e "s/e3;//"`
OFFSET=`grep "offset =" $GEO_FILE | awk '{print $3}' | sed -e "s/e3;//"`

# Kinematics
SLIP=`grep "DISP=" dobcs.sh | awk -F"=" '{print $2}'`

# Extract locations and magnitudes of slippery displacements
awk '{
  x = $2; y = $3; z = $4
  dx = $5; dy = $6; dz = $7
  print x,y,z,dx,dy,dz
}' flt_slip.dat > flt_slip_pre.tmp
awk '{
  x = $2; y = $3; z = $4
  dx = $5; dy = $6; dz = $7
  print x,y,z,dx,dy,dz
}' flt_slip_eq.dat > flt_slip_post.tmp
paste flt_slip_pre.tmp flt_slip_post.tmp |\
    awk '{print $1,$2,$3,$10-$4,$11-$5,$12-$6}' > flt_slip_eq.tmp
cp flt_slip_eq.tmp flt_slip.tmp

#####
#	PLOT RESULTS
#####
PSFILE="eq_slip.ps"

gmt set PS_MEDIA 17ix17i

# XMAX=`grep "^xmax =" $GEO_FILE | sed "s/;//" | awk '{print $3/1e3/'"$COSD"'}'`
XMAX=`grep "^xmax =" $GEO_FILE | sed "s/;//" | awk '{print $3/1e3}'`
YMAX=`grep "^ymax =" $GEO_FILE | sed "s/;//" | awk '{print $3/1e3}'`
LIMS="-R0/$YMAX/0/$XMAX"
PLOT_SCALE="0.008i"

XMIN=0
XMAX=250
YMIN=250
YMAX=750
LIMS="-R$YMIN/$YMAX/$XMIN/$XMAX"
PLOT_SCALE="0.012i"

PROJ="-Jx$PLOT_SCALE -P"


# Initialize plot
gmt psxy -T -K -X2i -Y2i > $PSFILE


# Contour displacement magnitude
# Coseismic slip color palette
colortool -hue 150,0 -chroma 0,80 -chroma:exp 1.6 -lightness 100,35 -gmt -T0/$SLIP/0.01 -D > slip.cpt
# Scale the slip to 5.4 meters of displacement since 1938
awk '{
    if (NF==4) {
        print $1*5.4,$2,$3*5.4,$4
    } else {
        print $0
    }
}' slip.cpt > slip_scaled.cpt
# Build connectivity file
awk '{printf("%d "),NR-1;if(NR%3==0){printf("\n")}}' flt_slip.tmp > conn.tmp
# Plot coseismic displacements as colored contours
awk '{print 1000-$2*1e-3,$1*1e-3,2*sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp |\
    gmt pscontour $PROJ $LIMS -Cslip.cpt -I -Econn.tmp -K -O >> $PSFILE
# Print maximum displacement
MAX_SLIP=`awk '{print 2*sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp | gmt gmtinfo -C | awk '{print $2*5.4}'`
echo MAX_SLIP=$MAX_SLIP
# Calculate slip at 15 km depth
YUPDIP=505000
ZUPDIP=-15000
awk 'BEGIN{mindist=100000;y0='$YUPDIP';z0='$ZUPDIP'}{
    dy = $2-y0
    dz = $3-z0
    d = sqrt(dy*dy+dz*dz)
    if (d<mindist) {
        mindist = d
        print $0
    }
}' flt_slip.tmp | tail -1 |\
    awk '{print $1,$2,2*sqrt($4*$4+$5*$5+$6*$6)*5.4,$3}' > xyslipupdip.tmp
X_UPDIP=`awk '{print $1}' xyslipupdip.tmp`
Y_UPDIP=`awk '{print $2}' xyslipupdip.tmp`
SLIP_UPDIP=`awk '{print $3}' xyslipupdip.tmp`
Z_UPDIP=`awk '{print $4}' xyslipupdip.tmp`
echo X_UPDIP=$X_UPDIP
echo Y_UPDIP=$Y_UPDIP
echo Z_UPDIP=$Z_UPDIP
echo SLIP_UPDIP=$SLIP_UPDIP
# Plot coseismic slip contour lines
CONT_INT_SCALED=0.5
CONT_INT=`echo ${CONT_INT_SCALED} 5.4 | awk '{print $1/$2}'`
awk '{print 1000-$2*1e-3,$1*1e-3,2*sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp |\
    gmt pscontour $PROJ $LIMS -C${CONT_INT} -W0.5p,45@35 -Econn.tmp -K -O >> $PSFILE


# Trench
gmt psxy $PROJ $LIMS -W1p -Sf1.0i/0.1i+t+l+o0.5i -Gblack -K -O >> $PSFILE << EOF
$YMIN $XMIN
$YMAX $XMIN
EOF



# Outline of Chignik rupture zone
CHIGNIK_LOCKED_STEP=$(grep "^UNLK_STEP_27=" doslipry.sh |\
    sed -e "/^#/d" -e "s/.*=//" -e "s/\"//g" |\
    tail -1 |\
    awk '{print $1}')
FXMIN=`sed -n -e "13p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "15p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "13p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "14p" tecin.dat.nps | awk '{print $4*1e-3}'`
cat > box.tmp << EOF
$FXMIN $FYMIN
$FXMIN $FYMAX
$FXMAX $FYMAX
$FXMAX $FYMIN
$FXMIN $FYMIN
EOF
if [ $CHIGNIK_LOCKED_STEP == 1 ]
then
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Locked"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
elif [ $CHIGNIK_LOCKED_STEP == -10 ]
then
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W0.25p,white -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Ruptured"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
fi


# Outline of eastern end of 1938 rupture zone
FXMIN=`sed -n -e "21p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "23p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "21p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "22p" tecin.dat.nps | awk '{print $4*1e-3}'`
cat > box.tmp << EOF
$FXMIN $FYMIN
$FXMIN $FYMAX
$FXMAX $FYMAX
$FXMAX $FYMIN
$FXMIN $FYMIN
EOF
awk '{print 1000-$2,$1}' box.tmp |\
    gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
    awk '{print $0,"Locked"}' |\
    gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE


# Outline of Shumagin Gap area
SG_LOCKED_STEP=$(grep "^UNLK_STEP_30=" doslipry.sh |\
    sed -e "/^#/d" -e "s/.*=//" -e "s/\"//g" |\
    tail -1 |\
    awk '{print $1}')
FXMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "19p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "18p" tecin.dat.nps | awk '{print $4*1e-3}'`
cat > box.tmp << EOF
$FXMIN $FYMIN
$FXMIN $FYMAX
$FXMAX $FYMAX
$FXMAX $FYMIN
$FXMIN $FYMIN
EOF
if [ $SG_LOCKED_STEP == 0 ]
then
    echo "$0: Shumagin Gap uncoupled"
    DASH=1_2:0
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,white,$DASH -K -O --PS_LINE_CAP=round >> $PSFILE
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W0.25p,black,$DASH -K -O --PS_LINE_CAP=round >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Unlocked"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
elif [ $SG_LOCKED_STEP == 1 ]
then
    echo "$0: Shumagin Gap coupled"
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Locked"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
fi


# Outline of updip 1938 asperity zone
UD_LOCKED=$(grep "^UNLK_STEP_32=" doslipry.sh |\
    sed -e "/^#/d" -e "s/.*=//" -e "s/\"//g" |\
    tail -1 |\
    awk '{if($1==0){print "N"}else{print "Y"}}')
UD_LOCKED_STEP=$(grep "^UNLK_STEP_32=" doslipry.sh |\
    sed -e "/^#/d" -e "s/.*=//" -e "s/\"//g" |\
    tail -1 |\
    awk '{print $1}')
FXMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "27p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "26p" tecin.dat.nps | awk '{print $4*1e-3}'`
cat > box.tmp << EOF
$FXMIN $FYMIN
$FXMIN $FYMAX
$FXMAX $FYMAX
$FXMAX $FYMIN
$FXMIN $FYMIN
EOF
if [ $UD_LOCKED_STEP == 0 ]
then
    echo "$0: updip zone uncoupled"
    # DASH=1_2:0
    # awk '{print 1000-$2,$1}' box.tmp |\
    #     gmt psxy $PROJ $LIMS -W1p,white,$DASH -K -O --PS_LINE_CAP=round >> $PSFILE
    # awk '{print 1000-$2,$1}' box.tmp |\
    #     gmt psxy $PROJ $LIMS -W0.25p,black,$DASH -K -O --PS_LINE_CAP=round >> $PSFILE
    # awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
    #     awk '{print $0,"Unlocked"}' |\
    #     gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
elif [ $UD_LOCKED_STEP == 10 ]
then
    echo "$0: updip zone locked co-seismically only"
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Locked Co-seismically"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
elif [ $UD_LOCKED_STEP == -10 ]
then
    echo "$0: updip zone is a ruptured asperity"
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W0.25p,white -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Ruptured"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
elif [ $UD_LOCKED_STEP == -100 ]
then
    echo "$0: updip zone always locked"
    awk '{print 1000-$2,$1}' box.tmp |\
        gmt psxy $PROJ $LIMS -W1p,black -K -O >> $PSFILE
    awk '{if(NR==1||NR==3){x[NR]=1000-$2;y[NR]=$1}}END{print (x[1]+x[3])/2,(y[1]+y[3])/2}' box.tmp |\
        awk '{print $0,"Locked"}' |\
        gmt pstext $PROJ $LIMS -F+f8,0+jCM -K -O >> $PSFILE
fi


# Slip vectors (of upper plate)
SCL="2"
NORM=`awk '{print sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp |\
      gmt gmtinfo -C |\
      awk '{print 0.5*$2*'"$SCL"'}'`
#awk 'BEGIN{sd='"$SIND"';cd='"$COSD"'}{
#    dx = cd*$4 - sd*$6
#    dy = $5
#    dz = sd*$4 + cd*$6
#    print $1/cd*1e-3,$2*1e-3,atan2(dy,dx)/0.01745,'"$SCL"'*sqrt(dx*dx+dy*dy)
#}' flt_slip.tmp |\
#    awk '{if(NR%3==0)print $0}' |\
#    gmt psxy $PROJ $LIMS -Sv10p+e+jb+n$NORM -W1p -Gblack -K -O -N -t50 >> $PSFILE


# Scale bar
MODEL_LEN=`echo $PLOT_SCALE $YMIN $YMAX | sed -e "s/i//" | awk '{print $1*($3-$2)}'`
MODEL_LEN_2=`echo $MODEL_LEN | awk '{print $1+0.1}'`
gmt psscale -Dx0i/-1.1i+w${MODEL_LEN}i/0.20i+h -Cslip_scaled.cpt \
    -Bg${CONT_INT_SCALED}a1.0+l"Coseismic Slip Magnitude (m)" -K -O \
    --MAP_GRID_PEN_PRIMARY=0.5p,55/55/55 >> $PSFILE
gmt psxy -JX20i -R0/20/0/20 -W0.65p+vb5p+gblack+a40+h0.25 -Ya-2.0i -K -O >> $PSFILE << EOF
$MODEL_LEN 0.9
$MODEL_LEN 0.7
$MODEL_LEN_2 0.65
EOF
gmt pstext -JX20i -R0/20/0/20 -F+f+j -Ya-2.0i -D0.025i/0 -K -O >> $PSFILE << EOF
$MODEL_LEN_2 0.65 11,0 LM 5.4 m
EOF


# Labels
FXMAX=`sed -n -e "23p" tecin.dat.nps | awk '{print $3*1e-3}'`
BRACKET_MIN=$(echo $FXMAX | awk '{print $1+10}')
BRACKET_MAX=$(echo $FXMAX | awk '{print $1+20}')
BRACKET_MIN_2=$(echo $FXMAX | awk '{print $1+10-65}')
BRACKET_MAX_2=$(echo $FXMAX | awk '{print $1+20-65}')
gmt psxy $PROJ $LIMS -W1p -K -O >> $PSFILE << EOF
#> # 1946 Rupture Zone
#160 $BRACKET_MIN
#160 $BRACKET_MAX
#360 $BRACKET_MAX
#360 $BRACKET_MIN
> # Shumagin Gap
300 $BRACKET_MIN
300 $BRACKET_MAX
465 $BRACKET_MAX
465 $BRACKET_MIN
> # 1938 Asperity
470 $BRACKET_MIN
470 $BRACKET_MAX
700 $BRACKET_MAX
700 $BRACKET_MIN
EOF
gmt pstext $PROJ $LIMS -F+f+j+a -D0/0.05i -K -O >> $PSFILE << EOF
#260 $BRACKET_MAX 16,2 CB 0 1946 Asperity?
382.5 $BRACKET_MAX 14,2 CB 0 Shumagin Gap
585 $BRACKET_MAX 14,2 CB 0 1938 Asperity
EOF
if [ $UD_LOCKED == "N" ]
then
    echo 470 $BRACKET_MAX_2 > bracket.tmp
    echo 470 $BRACKET_MIN_2 >> bracket.tmp
    echo 530 $BRACKET_MIN_2 >> bracket.tmp
    echo 530 $BRACKET_MAX_2 >> bracket.tmp
    gmt psxy bracket.tmp $PROJ $LIMS -W1p -K -O >> $PSFILE
    echo 500 $BRACKET_MIN_2 12,2 CT 0 2021 Chignik Zone |\
        gmt pstext $PROJ $LIMS -F+f+j+a -D0/-0.05i -K -O >> $PSFILE
fi
if [ $SG_LOCKED_STEP == 0 -a $UD_LOCKED_STEP == 0 ]
then
    echo "(a) Unlocked Shumagin Gap" | gmt pstext $PROJ $LIMS -F+cTL+f16,1 -D0.05i/-0.05i -K -O >> $PSFILE
elif [ $SG_LOCKED_STEP == 1 -a $UD_LOCKED_STEP == 0 ]
then
    echo "(b) Locked Shumagin Gap" | gmt pstext $PROJ $LIMS -F+cTL+f16,1 -D0.05i/-0.05i -K -O >> $PSFILE
elif [ $SG_LOCKED_STEP == 0 -a $UD_LOCKED_STEP == "-100" ]
then
    echo "(b) Updip Asperity Locked" | gmt pstext $PROJ $LIMS -F+cTL+f16,1 -D0.05i/-0.05i -K -O >> $PSFILE
elif [ $SG_LOCKED_STEP == 0 -a $UD_LOCKED_STEP == "10" ]
then
    echo "(c) Updip Strain-Rate-Strengthening Patch" | gmt pstext $PROJ $LIMS -F+cTL+f16,1 -D0.05i/-0.05i -K -O >> $PSFILE
elif [ $SG_LOCKED_STEP == 0 -a $UD_LOCKED_STEP == "-10" ]
then
    echo "(a) Updip Asperity Ruptured" | gmt pstext $PROJ $LIMS -F+cTL+f16,1 -D0.05i/-0.05i -K -O >> $PSFILE
fi
echo $MAX_SLIP | awk '{printf("Maximum slip = %.2f m"),$1}' |\
    gmt pstext $PROJ $LIMS -F+cBL+f12,3 -D0.05i/0.15i -K -O >> $PSFILE
echo $X_UPDIP $Y_UPDIP | awk '{print 1000-$2/1e3,$1/1e3}' |\
    gmt psxy $PROJ $LIMS -Sc0.08i -W1.2p -K -O >> $PSFILE
echo $X_UPDIP $Y_UPDIP $SLIP_UPDIP | awk '{printf("%.4f %.4f Updip slip = %.2f m"),1000-$2/1e3,$1/1e3,$3}' |\
    gmt pstext $PROJ $LIMS -F+jRM+f10,3 -D-0.25i/-0.031i -K -O >> $PSFILE
STR1=`echo $Y_UPDIP | awk '{print 1000-$1/1e3-20}'`
DIS1=`echo $X_UPDIP | awk '{print $1/1e3-6}'`
STR2=`echo $Y_UPDIP | awk '{print 1000-$1/1e3-13}'`
DIS2=`echo $X_UPDIP | awk '{print $1/1e3-8}'`
STR3=`echo $Y_UPDIP | awk '{print 1000-$1/1e3-2.5}'`
DIS3=`echo $X_UPDIP | awk '{print $1/1e3-2}'`
gmt psxy $PROJ $LIMS -W1p+s+ve5p+a45+h0.25+gblack -K -O >> $PSFILE << EOF
$STR1 $DIS1
$STR2 $DIS2
$STR3 $DIS3
EOF

# Basemap
gmt psbasemap $PROJ $LIMS -Bxa1e2+l"Distance Along Strike (km)" -Bya50+l"Distance From Trench (km)" -BWSn -K -O >> $PSFILE
DMIN=`echo $XMIN $SIND | awk '{print $1*$2}'`
DMAX=`echo $XMAX $SIND | awk '{print $1*$2}'`
DSCL=`echo $PLOT_SCALE $XMAX $DMAX | sed -e "s/i//" | awk '{print $1*$2/$3}'`
gmt psbasemap -Jx$PLOT_SCALE/${DSCL}i -R$YMIN/$YMAX/$DMIN/$DMAX -P -Bya10+l"Depth (km)" -BE -K -O >> $PSFILE

# Finalize PostScript
echo 0 0 | gmt psxy $PROJ $LIMS -O >> $PSFILE

gmt psconvert $PSFILE -Tf -A
gmt psconvert $PSFILE -Tg -A
cp `basename $PSFILE .ps`.pdf `basename $PSFILE .ps`_SG-${SG_LOCKED}_UD-${UD_LOCKED}${UD_LOCKED_STEP}.pdf
cp `basename $PSFILE .ps`.png `basename $PSFILE .ps`_SG-${SG_LOCKED}_UD-${UD_LOCKED}${UD_LOCKED_STEP}.png

cp flt_slip.dat    flt_slip_SG-${SG_LOCKED}_UD-${UD_LOCKED}.dat
cp flt_slip_eq.dat flt_slip_eq_SG-${SG_LOCKED}_UD-${UD_LOCKED}.dat

rm $PSFILE
rm *.tmp
rm *.cpt
rm gmt.*
