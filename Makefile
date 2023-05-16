GTECTON_BIN_DIR = /home/mherman2/Research/gtecton/build
MPI_BIN_DIR = /home/mherman2/Research/openmpi-4.1.4_gcc-9/bin

#####
#	MODEL SETUP
#####
GEO_FILE = subduction.geo
MSH_FILE = subduction.msh

NNODE = 1
NPROC = 28


all: mesh bcs tecin partition

#---- Create mesh and GTECTON node and element files
mesh: $(MSH_FILE) tecin.dat.nps tecin.dat.elm
$(MSH_FILE) tecin.dat.nps tecin.dat.elm: $(GEO_FILE) domesh.sh
	domesh.sh $(GEO_FILE) $(MSH_FILE) --gtecton-bin-dir=$(GTECTON_BIN_DIR)

#---- Generate boundary condition files
bcs: tecin.dat.bcs tecin.dat.slp
tecin.dat.bcs: $(MSH_FILE) dobcs.sh
	dobcs.sh $(GEO_FILE) $(MSH_FILE) --gtecton-bin-dir=$(GTECTON_BIN_DIR) > tecin.dat.bcs
tecin.dat.slp: $(MSH_FILE) doslipry.sh
	doslipry.sh $(MSH_FILE) --gtecton-bin-dir=$(GTECTON_BIN_DIR) > tecin.dat.slp

#---- Set up run input file
tecin: TECIN.DAT
TECIN.DAT: tecin.dat.bcs tecin.dat.slp dotecin.sh
	dotecin.sh > TECIN.DAT

#---- Partition model for parallel processing
partition: partition.info tecin.dat.partf.nps tecin.dat.partf.elm
partition.info tecin.dat.partf.nps tecin.dat.partf.elm: tecin.dat.nps tecin.dat.elm
	dopart.sh $(NNODE) $(NPROC) --gtecton-bin-dir=$(GTECTON_BIN_DIR)


#####
#	RUN MODEL
#####

#---- Run FEM
fem:
	dofem.sh $(NNODE) $(NPROC) --gtecton-bin-dir=$(GTECTON_BIN_DIR) --mpi-bin-dir=$(MPI_BIN_DIR)

#---- Extract results
extract:
	doextract.sh $(GEO_FILE) $(MSH_FILE) --gtecton-bin-dir=$(GTECTON_BIN_DIR) 

#---- Plot results
plot: eq_slip.pdf
eq_slip.pdf: plot_eq_slip.sh FEDSK.DAT.00
	plot_eq_slip.sh


#####
#	CLEAN UP
#####
clean:
	-rm residu.dat.*
	-rm modeldata.dat*
	-rm FEM*
	-rm STATUS
	-rm petsc_interface.log
	-rm BTOT.DAT
	-rm conn.dat
	-rm extract.s
	-rm GTecton.rc

veryclean: clean
	-rm FEDSK.DAT.*

veryveryclean: veryclean
	-rm tecin.dat.*
	-rm TECIN.DAT
	-rm subduction.msh
	-rm partition.info
