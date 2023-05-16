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
PROJ="-Jx$PLOT_SCALE -P"


# Initialize plot
gmt psxy -T -K -X2i -Y2i > $PSFILE


# Contour displacement magnitude
# Coseismic slip color palette
colortool -hue 180,20 -chroma 5,80 -chroma:exp 2 -lightness 100,40 -gmt -T0/$SLIP/0.02 -D > slip.cpt
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
awk '{print 2*sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp | gmt gmtinfo -C | awk '{print $2*5.4}'
# Plot 0.1 meter coseismic slip contour lines
awk '{print 1000-$2*1e-3,$1*1e-3,2*sqrt($4*$4+$5*$5+$6*$6)}' flt_slip.tmp |\
    gmt pscontour $PROJ $LIMS -C0.1 -W0.5p,25@25 -Econn.tmp -K -O >> $PSFILE


# Trench
gmt psxy $PROJ $LIMS -W1p -Sf1.0i/0.1i+t+l+o0.5i -Gblack -K -O >> $PSFILE << EOF
0 0
1000 0
EOF


# Outline Shumagin Gap
SG_LOCKED=$(grep "UNLK_STEP_30=" doslipry.sh |\
    sed -e "/^#/d" -e "s/.*=//" -e "s/\"//g" |\
    tail -1 |\
    awk '{if($1<19){print "N"}else{print "Y"}}')
echo SG_LOCKED=$SG_LOCKED
if [ "$SG_LOCKED" == "N" ]
then
    SG_PEN=-W0.5p,black,4_2:0
else
    SG_PEN=-W0.5p,black
fi
# FXMIN=`sed -n -e "13p" tecin.dat.nps | awk '{print $3/'"$COSD"'*1e-3}'`
# FXMAX=`sed -n -e "15p" tecin.dat.nps | awk '{print $3/'"$COSD"'*1e-3}'`
FXMIN=`sed -n -e "13p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "15p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "13p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "14p" tecin.dat.nps | awk '{print $4*1e-3}'`
echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
    awk '{print 1000-$2,$1}' |\
    gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
    awk '{print 1000-$2,$1}' |\
    gmt psxy $PROJ $LIMS -W0.5p,black -K -O >> $PSFILE


UNLK_STEP_30=`grep "^UNLK_STEP_30" doslipry.sh | tail -1 | sed -e "s/UNLK_STEP_30=//" | awk '{print $1}'`
if [ $UNLK_STEP_30 == "-100" ]
then
    FXMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FXMAX=`sed -n -e "19p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FYMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $4*1e-3}'`
    FYMAX=`sed -n -e "18p" tecin.dat.nps | awk '{print $4*1e-3}'`
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W0.5p,black,4_2:0 -K -O >> $PSFILE
elif [ $UNLK_STEP_30 == 0 ]
then
    FXMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FXMAX=`sed -n -e "19p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FYMIN=`sed -n -e "17p" tecin.dat.nps | awk '{print $4*1e-3}'`
    FYMAX=`sed -n -e "18p" tecin.dat.nps | awk '{print $4*1e-3}'`
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W0.5p,black,4_2:0 -K -O >> $PSFILE
fi

UNLK_STEP_32=`grep "^UNLK_STEP_32" doslipry.sh | tail -1 | sed -e "s/UNLK_STEP_32=//" | awk '{print $1}'`
if [ $UNLK_STEP_32 == "-100" ]
then
    # Up-dip locked patch
    FXMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FXMAX=`sed -n -e "27p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FYMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $4*1e-3}'`
    FYMAX=`sed -n -e "26p" tecin.dat.nps | awk '{print $4*1e-3}'`
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W0.5p,black -K -O >> $PSFILE
elif [ $UNLK_STEP_32 == "10" ]
then
    # Up-dip locked patch
    FXMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FXMAX=`sed -n -e "27p" tecin.dat.nps | awk '{print $3*1e-3}'`
    FYMIN=`sed -n -e "25p" tecin.dat.nps | awk '{print $4*1e-3}'`
    FYMAX=`sed -n -e "26p" tecin.dat.nps | awk '{print $4*1e-3}'`
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
    echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
        awk '{print 1000-$2,$1}' |\
        gmt psxy $PROJ $LIMS -W0.5p,black,4_2:0 -K -O >> $PSFILE
fi

# FXMIN=`sed -n -e "21p" tecin.dat.nps | awk '{print $3/'"$COSD"'*1e-3}'`
# FXMAX=`sed -n -e "23p" tecin.dat.nps | awk '{print $3/'"$COSD"'*1e-3}'`
FXMIN=`sed -n -e "21p" tecin.dat.nps | awk '{print $3*1e-3}'`
FXMAX=`sed -n -e "23p" tecin.dat.nps | awk '{print $3*1e-3}'`
FYMIN=`sed -n -e "21p" tecin.dat.nps | awk '{print $4*1e-3}'`
FYMAX=`sed -n -e "22p" tecin.dat.nps | awk '{print $4*1e-3}'`
echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
    awk '{print 1000-$2,$1}' |\
    gmt psxy $PROJ $LIMS -W1p,white -K -O >> $PSFILE
echo "$FXMIN $FYMIN\n$FXMIN $FYMAX\n$FXMAX $FYMAX\n$FXMAX $FYMIN\n$FXMIN $FYMIN" |\
    awk '{print 1000-$2,$1}' |\
    gmt psxy $PROJ $LIMS -W0.5p,black -K -O >> $PSFILE

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
gmt psscale -Dx1.0i/-1.1i+w6.0i/0.20i+h -Cslip_scaled.cpt -Bg0.2a1.0+l"Slip Magnitude (m)" -K -O \
    --MAP_GRID_PEN_PRIMARY=0.5p,55/55/55 >> $PSFILE

# Labels
BRACKET_MIN=$(echo $FXMAX | awk '{print $1+10}')
BRACKET_MAX=$(echo $FXMAX | awk '{print $1+20}')
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

# Basemap
# gmt psbasemap $PROJ $LIMS -Bxa1e2+l"Along-Strike (km)" -Bya1e2+l"Along-Dip (km)" -BWSn -K -O >> $PSFILE
gmt psbasemap $PROJ $LIMS -Bxa1e2+l"Distance Along Strike (km)" -Bya1e2+l"Distance From Trench (km)" -BWSn -K -O >> $PSFILE
DMAX=`echo $XMAX $SIND | awk '{print $1*$2}'`
DSCL=`echo $PLOT_SCALE $XMAX $DMAX | sed -e "s/i//" | awk '{print $1*$2/$3}'`
gmt psbasemap -Jx$PLOT_SCALE/${DSCL}i -R0/$YMAX/0/$DMAX -P -Bya2e1+l"Depth (km)" -BE -K -O >> $PSFILE

# Finalize PostScript
echo 0 0 | gmt psxy $PROJ $LIMS -O >> $PSFILE

gmt psconvert $PSFILE -Tf -A
gmt psconvert $PSFILE -Tg -A
rm $PSFILE
cp flt_slip.tmp flt_slip_${FLT_WID}_${FLT_LEN}_${OFFSET}.dat
rm *.tmp
rm *.cpt
rm gmt.*
