export ndx=${1:-"./../1-refinement/0-Building/index.ndx"}
ndx=$(realpath --relative-to=. "$ndx")

export pdb=${2:-"../../1-refinement/3-Map-Scaling/step3_input_xtc.pdb"}
pdb=$(realpath --relative-to=. "$pdb")

export DDIR=${3:-"../0-Production"}
DDIR=$(realpath --relative-to=. "$DDIR")

# 1) concatenate all the trajectories from multiple replicas -> traj-all.xtc
gmx_mpi trjcat -f ${DDIR}/rep-*/traj*.xtc -cat -o traj-all.xtc

# 2) fix PBCs with PLUMED and select only map atoms -> traj-all-PBC.xtc
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
sed ${SCRIPT_DIR}/plumed_fix_pbc.dat \
    -e "s|../../1-refinement/3-Map-Scaling/step3_input_xtc.pdb|$pdb|g" \
    -e "s|../../1-refinement/0-Building/index.ndx|$ndx|g" > plumed_fix_pbc.dat

plumed driver --plumed plumed_fix_pbc.dat --mf_xtc traj-all.xtc

# 3) extract from pdb only the atoms used to generate the cryo-em map. 
echo System-MAP-H | gmx_mpi trjconv -f $pdb -s ${DDIR}/rep-00/production.tpr -n $ndx -o conf_map.pdb

