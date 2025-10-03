#!/bin/bash
export PLUMED_NUM_THREADS=$1
export logfile=${2:-"../1-Map-Preparation/log.preprocess"}
export gro=${3:-"../2-Equilibration/em.gro"}
export ndx=${4:-"../0-Building/index.ndx"}
export pdb=${5:-"step3_input_xtc.pdb"}
export tpr=${6:-"../2-Equilibration/em.tpr"}
export xtc=${7:-"../../2-Equilibration/nvt_posres.xtc"}

# number of CPU cores used by PLUMED 
export PLUMED_NUM_THREADS=$1
# extract NORM_DENSITY and RESOLUTION from `../1-Map-Preparation/log.preprocess` 
n=`grep NORM_DENSITY $logfile | awk '{print $NF}'`
r=`grep Resolution $logfile | awk '{print $NF/10.0}'`

# create a PDB file with only the XTC atoms
echo System-XTC | gmx_mpi trjconv -f $gro -n $ndx -o $pdb -pbc nojump -s $tpr

# loop over scale values
for d in $(seq 0.7 0.05 1.3)
do 
        # create directory and go into
	mkdir s-${d}; cd s-${d}
        # create plumed input file for postprocessing
        sed -e "s/NORM_DENSITY_/$n/g" ../plumed_EMMI_template_BFACT.dat | sed -e "s/RESOLUTION_/$r/g" | sed -e "s/SCALE_/$d/g" > plumed.dat
        # run PLUMED driver to calculate EMMIVOX score
        plumed driver --plumed plumed.dat --mf_xtc $xtc > log.plumed
        # go back to root 	
	cd ../
done
# find scale value that minimize energy
cat s-*/COLVAR | grep -v FIELD | sort -n -k 2 | head -n 1 | awk '{print "BEST_SCALE: ",$3}' > BEST_SCALE
