// Simple subduction zone geometry, uniform elastic properties, one rectangular fault

// Characteristic lengths for meshing
//
lc_vol = 1e5;        // volume characteristic size
lc_meg = 5e4;        // megathrust characteristic size
lc_flt = 4e4;        // fault segment characteristic size
// //
// lc_vol = 5e4;        // volume characteristic size
// lc_meg = 2.5e4;        // megathrust characteristic size
// lc_flt = 2.5e4;        // fault segment characteristic size
// //
// // lc_vol = 3e4;        // volume characteristic size
// // lc_meg = 1e4;        // megathrust characteristic size
// // lc_flt = 1e4;        // fault segment characteristic size
// //
// lc_vol = 4e4;        // volume characteristic size
// lc_meg = 1.25e4;        // megathrust characteristic size
// lc_flt = 5e3;        // fault segment characteristic size
// //
lc_vol = 2.0e4;        // volume characteristic size
lc_meg = 1e4;        // megathrust characteristic size
lc_flt = 2.5e3;        // fault segment characteristic size

// Geometric parameters of subduction zone
d2r = 0.017453;                     // degrees to radians
dip = 15;
sind = Sin(dip*d2r);
cosd = Cos(dip*d2r);
tand = Tan(dip*d2r);
thk = 100e3;                        // perpendicular thickness of subducting slab
zthk = thk/cosd;                    // vertical thickness of subducting slab
xmin = -100e3;                      // horizontal extent of subducting slab
xmax = 500e3;                       // horizontal extent of upper and subducting
zmax_xmin = -xmin*tand;
zmin_xmin = zmax_xmin - zthk;
zmax_xmax = -xmax*tand;
zmin_xmax = zmax_xmax - zthk;
ymin = 0;                           // near-strike model boundary
ymax = 1000e3;                      // far-strike model boundary

// Fault parameters
nflt = 2;
offset = 240e3;
flt_len = 200e3;                    // along-strike length of fault patch
y0 = (ymax+ymin)*0.5;              // along-strike center of fault patch
ymin_flt = y0 - 0.5*flt_len;
ymax_flt = y0 + 0.5*flt_len;
// Faults separated along strike
ymax_flt_b = 700e3; // Shumagin gap patch
ymin_flt_b = 560e3;
ymax_flt_a = 530e3; // Central patch
ymin_flt_a = 470e3;
ymax_flt_c = 440e3; // 1938 eastern patch
ymin_flt_c = 300e3;
ymax_flt_d = 500e3; // Up-dip patch
ymin_flt_d = 400e3;


dimension = 1;
If (dimension == 1)
    flt_wid = 40e3;                     // along-dip width of fault patch
    z0 = -30e3;                         // depth of fault patch
    x0 = -z0/tand;                      // along-dip center of fault patch
    z1 = -15e3;                         // depth of fault patch
    x1 = -z1/tand;                      // along-dip center of fault patch
    // Faults separated along strike
    xmin_flt_a = x0 - 0.5*flt_wid*cosd;
    xmax_flt_a = x0 + 0.5*flt_wid*cosd;
    zmin_flt_a = z0 - 0.5*flt_wid*sind;
    zmax_flt_a = z0 + 0.5*flt_wid*sind;
    xmin_flt_b = x0 - 0.5*flt_wid*cosd;
    xmax_flt_b = x0 + 0.5*flt_wid*cosd;
    zmin_flt_b = z0 - 0.5*flt_wid*sind;
    zmax_flt_b = z0 + 0.5*flt_wid*sind;
    xmin_flt_c = x0 - 0.5*flt_wid*cosd;
    xmax_flt_c = x0 + 0.5*flt_wid*cosd;
    zmin_flt_c = z0 - 0.5*flt_wid*sind;
    zmax_flt_c = z0 + 0.5*flt_wid*sind;
    xmin_flt_d = x1 - 0.5*flt_wid*cosd;
    xmax_flt_d = x1 + 0.5*flt_wid*cosd;
    zmin_flt_d = z1 - 0.5*flt_wid*sind;
    zmax_flt_d = z1 + 0.5*flt_wid*sind;
EndIf
If (dimension == 0)
    zmin_flt = -50e3;
    zmax_flt = -10e3;
    xmin_flt = -zmax_flt/tand;
    xmax_flt = -zmin_flt/tand;
EndIf

/*-----------------------------*/
/*----- POINT DEFINITIONS -----*/
/*-----------------------------*/
// y=0 points
Point(1)  = {       0,    0,              0, lc_meg}; // trench
Point(2)  = {    xmax,    0,              0, lc_vol}; // backside; surface
Point(3)  = {    xmax,    0,      zmax_xmax, lc_meg}; // backside; megathrust
Point(4)  = {    xmax,    0,      zmin_xmax, lc_vol}; // backside; bottom
Point(5)  = {    xmin,    0,      zmin_xmin, lc_vol}; // frontside; bottom
Point(6)  = {    xmin,    0,      zmax_xmin, lc_vol}; // frontside; top
// y=ymax points
Point(7)  = {       0, ymax,              0, lc_meg}; // trench
Point(8)  = {    xmax, ymax,              0, lc_vol}; // backside; surface
Point(9)  = {    xmax, ymax,      zmax_xmax, lc_meg}; // backside; megathrust
Point(10) = {    xmax, ymax,      zmin_xmax, lc_vol}; // backside; bottom
Point(11) = {    xmin, ymax,      zmin_xmin, lc_vol}; // frontside; bottom
Point(12) = {    xmin, ymax,      zmax_xmin, lc_vol}; // frontside; top
// fault rectangle points
Point(13) = {xmin_flt_a, ymin_flt_a, zmax_flt_a, lc_flt}; // updip, near strike corner
Point(14) = {xmin_flt_a, ymax_flt_a, zmax_flt_a, lc_flt}; // updip, far strike corner
Point(15) = {xmax_flt_a, ymax_flt_a, zmin_flt_a, lc_flt}; // downdip, far strike corner
Point(16) = {xmax_flt_a, ymin_flt_a, zmin_flt_a, lc_flt}; // downdip, near strike corner
Point(17) = {xmin_flt_b, ymin_flt_b, zmax_flt_b, lc_flt}; // updip, near strike corner
Point(18) = {xmin_flt_b, ymax_flt_b, zmax_flt_b, lc_flt}; // updip, far strike corner
Point(19) = {xmax_flt_b, ymax_flt_b, zmin_flt_b, lc_flt}; // downdip, far strike corner
Point(20) = {xmax_flt_b, ymin_flt_b, zmin_flt_b, lc_flt}; // downdip, near strike corner
Point(21) = {xmin_flt_c, ymin_flt_c, zmax_flt_c, lc_flt}; // updip, near strike corner
Point(22) = {xmin_flt_c, ymax_flt_c, zmax_flt_c, lc_flt}; // updip, far strike corner
Point(23) = {xmax_flt_c, ymax_flt_c, zmin_flt_c, lc_flt}; // downdip, far strike corner
Point(24) = {xmax_flt_c, ymin_flt_c, zmin_flt_c, lc_flt}; // downdip, near strike corner
Point(25) = {xmin_flt_d, ymin_flt_d, zmax_flt_d, lc_flt}; // updip, near strike corner
Point(26) = {xmin_flt_d, ymax_flt_d, zmax_flt_d, lc_flt}; // updip, far strike corner
Point(27) = {xmax_flt_d, ymax_flt_d, zmin_flt_d, lc_flt}; // downdip, far strike corner
Point(28) = {xmax_flt_d, ymin_flt_d, zmin_flt_d, lc_flt}; // downdip, near strike corner
Coherence;

/*----------------------------*/
/*----- LINE DEFINITIONS -----*/
/*----------------------------*/
Line(1)  = {1,2};
Line(2)  = {2,3};
Line(3)  = {3,4};
Line(4)  = {4,5};
Line(5)  = {5,6};
Line(6)  = {6,1};
Line(7)  = {1,3};

Line(8)  = {7,8};
Line(9)  = {8,9};
Line(10) = {9,10};
Line(11) = {10,11};
Line(12) = {11,12};
Line(13) = {12,7};
Line(14) = {7,9};

Line(15) = {1,7};
Line(16) = {2,8};
Line(17) = {3,9};
Line(18) = {4,10};
Line(19) = {5,11};
Line(20) = {6,12};

Line(21) = {13,14};
Line(22) = {14,15};
Line(23) = {15,16};
Line(24) = {16,13};
Line(25) = {17,18};
Line(26) = {18,19};
Line(27) = {19,20};
Line(28) = {20,17};
Line(29) = {21,22};
Line(30) = {22,23};
Line(31) = {23,24};
Line(32) = {24,21};
Line(33) = {25,26};
Line(34) = {26,27};
Line(35) = {27,28};
Line(36) = {28,25};

/*-------------------------------*/
/*----- Surface Definitions -----*/
/*-------------------------------*/
// y = 0 side
Line Loop(1) = {1, 2, -7};
Plane Surface(1) = {1};
Line Loop(2) = {3, 4, 5, 6, 7};
Plane Surface(2) = {2};
// y = ymax side
Line Loop(3) = {8, 9, -14};
Plane Surface(3) = {3};
Line Loop(4) = {12, 13, 14, 10, 11};
Plane Surface(4) = {4};

// x = xmax
Line Loop(5) = {16, 9, -17, -2}; // upper plate
Plane Surface(5) = {5};
Line Loop(6) = {18, -10, -17, 3}; // subducting plate
Plane Surface(6) = {6};
// x = xmin
Line Loop(7) = {20, -12, -19, 5};
Plane Surface(7) = {7};

// free top and bottom of subducting plate
Line Loop(8) = {15, -13, -20, 6}; // top
Plane Surface(8) = {8};
Line Loop(9) = {11, -19, -4, 18}; // bottom
Plane Surface(9) = {9};
// free top of upper plate
Line Loop(10) = {16, -8, -15, 1};
Plane Surface(10) = {10};

// megathrust
Line Loop(11) = {15, 14, -17, -7}; // entire area
Line Loop(12) = {24, 21, 22, 23}; // locked region
Plane Surface(12) = {12};
Line Loop(13) = {25, 26, 27, 28};
Line Loop(14) = {29, 30, 31, 32};
Line Loop(15) = {33, 34, 35, 36};
Plane Surface(11) = {11,12,13,14,15};
Plane Surface(13) = {13};
Plane Surface(14) = {14};
Plane Surface(15) = {15};

/*------------------------------*/
/*----- VOLUME DEFINITIONS -----*/
/*------------------------------*/
// upper plate
Surface Loop(1) = {11, 12, 13, 14, 15, 3, 10, 5, 1};
// subducting plate
Surface Loop(2) = {8, 4, 7, 9, 2, 6, 11, 12, 13, 14, 15};
Volume(1) = {1};
Volume(2) = {2};

/*---------------------------------------*/
/*----- PHYSICAL ENTITY DEFINITIONS -----*/
/*---------------------------------------*/
// Use physical numbers 1-20 for materials:
Physical Volume(1) = {1};
Physical Volume(2) = {2};

Physical Surface(21) = {1,2};      // y=0
Physical Surface(22) = {3,4};      // y=ymax
Physical Surface(23) = {5};        // x=xmax; upper plate
Physical Surface(24) = {6};        // x=xmax; subducting plate
Physical Surface(25) = {7};        // x=xmin; lower plate
Physical Surface(26) = {11};       // megathrust sliding
Physical Surface(27) = {12};       // shumagin gap
Physical Surface(30) = {13};       // unlocked western 1938 asperity
Physical Surface(31) = {14};       // locked eastern 1938 asperity
Physical Surface(32) = {15};       // updip 1938 asperity
Physical Surface(28) = {10};       // horizontal surface
Physical Surface(29) = {8};        // top of subducting plate outboard of trench

Physical Line(41) = {17};          // megathrust at x=xmax
Physical Line(42) = {15};          // megathrust at x=0
Physical Line(43) = {21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36}; // Fault outline
Physical Line(44) = {7,14};        // Megathrust side lines
Physical Line(45) = {16};          // Back, top of upper plate wedge
