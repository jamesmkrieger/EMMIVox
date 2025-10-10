#!/bin/bash        
DDIR=${1:-"../4-Production"}
DDIR=$(realpath --relative-to=. "$DDIR")

# extract NORM_DENSITY and RESOLUTION from `../1-Map-Preparation/log.preprocess` 
# and BEST_SCALE from ../3-Map-Scaling/BEST_SCALE
export logfile=${2:-"../1-Map-Preparation/log.preprocess"}
export bestscalefile=${3:-"../3-Map-Scaling/BEST_SCALE"}

export ndx=${4:-"../0-Building/index.ndx"}
ndx=$(realpath --relative-to=. "$ndx")

export pdb=${5:-"../3-Map-Scaling/step3_input_xtc.pdb"}
pdb=$(realpath --relative-to=. "$pdb")

export datafile=${6:-"../../1-Map-Preparation/emd_plumed_aligned.dat"}
datafile=$(realpath --relative-to=. "$datafile")

not_homomer=${7:-0}

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# extract NORM_DENSITY and RESOLUTION from `../1-Map-Preparation/log.preprocess` 
# and BEST_SCALE from ../3-Map-Scaling/BEST_SCALE
n=`grep NORM_DENSITY $logfile | awk '{print $NF}'`
r=`grep Resolution $logfile | awk '{print $NF/10.0}'`
s=`grep BEST_SCALE $bestscalefile | awk '{print $NF}'`

# create plumed input file for production 
sed -e "s/NORM_DENSITY_/$n/g" ${SCRIPT_DIR}/plumed_EMMI_emin_template.dat \
    -e "s/RESOLUTION_/$r/g" -e "s/SCALE_/$s/g" \
    -e "s|../3-Map-Scaling/step3_input_xtc.pdb|$pdb|g" \
    -e "s|../0-Building/index.ndx|$ndx|g" \
    -e "s|../1-Map-Preparation/emd_plumed_aligned.dat|$datafile|g" > plumed_EMMI_emin.dat

if [ "$not_homomer" -ne 0 ]; then
    # Comment out BFACT_NOCHAIN
    sed -e "s/BFACT_NOCHAIN/#BFACT_NOCHAIN/g" plumed_EMMI_emin.dat > plumed_EMMI_emin.dat
fi

# Extract lowest energy frame from the single structure refinement (4-Production)
# get time (ps) of the frame with best score
b=`grep -v FIELDS ${DDIR}/COLVAR | sort -n -k 2 | head -n 1 | awk '{print $1}'`
# get the line of COLVAR corresponding to this frame
line=`awk '{print NR, $0}' ${DDIR}/COLVAR | grep -v FIELDS | sort -n -k 3 | head -n 1 | awk '{print $1}'`

# extract best frame (entire system)
echo 0 | gmx_mpi trjconv -f ${DDIR}/production.trr -o conf_best.gro -dump $b -s ${DDIR}/production.tpr

# create Bfactor file and take header
sed -n 1p ${DDIR}/EMMIStatus > EMMIStatus
# get the value of the line that has the lowest energy
sed -n ${line}p ${DDIR}/EMMIStatus >> EMMIStatus
