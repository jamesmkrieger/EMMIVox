#!/bin/bash
export logfile=${1:-"../1-Map-Preparation/log.preprocess"}
export bestscalefile=${2:-"../3-Map-Scaling/BEST_SCALE"}

export ndx=${3:-"../0-Building/index.ndx"}
ndx=$(realpath --relative-to=. "$ndx")

export pdb=${4:-"../3-Map-Scaling/step3_input_xtc.pdb"}
pdb=$(realpath --relative-to=. "$pdb")

export datafile=${5:-"../../1-Map-Preparation/emd_plumed_aligned.dat"}
datafile=$(realpath --relative-to=. "$datafile")

# extract NORM_DENSITY and RESOLUTION from `../1-Map-Preparation/log.preprocess` 
# and BEST_SCALE from ../3-Map-Scaling/BEST_SCALE
n=`grep NORM_DENSITY $logfile | awk '{print $NF}'`
r=`grep Resolution $logfile | awk '{print $NF/10.0}'`
s=`grep BEST_SCALE $bestscalefile | awk '{print $NF}'`

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# create plumed input file for production 
sed -e "s/NORM_DENSITY_/$n/g" ${SCRIPT_DIR}/plumed_EMMI_template.dat \
    -e "s/RESOLUTION_/$r/g" -e "s/SCALE_/$s/g" \
    -e "s|../3-Map-Scaling/step3_input_xtc.pdb|$pdb|g" \
    -e "s|../0-Building/index.ndx|$ndx|g" \
    -e "s|../1-Map-Preparation/emd_plumed_aligned.dat|$datafile|g" > plumed_EMMI.dat
