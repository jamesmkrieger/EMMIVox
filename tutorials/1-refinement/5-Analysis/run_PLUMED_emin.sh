# Run energy minimization
export mdp=${2:-"../2-Equilibration/0-em-steep.mdp"}
mdp=$(realpath --relative-to=. "$mdp")

export topol=${3:-"../0-Building/topol.top"}
topol=$(realpath --relative-to=. "$topol")

export ndx=${4:-"../0-Building/index.ndx"}
ndx=$(realpath --relative-to=. "$ndx")

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

gmx_mpi grompp -f $mdp -c conf_best.gro -r conf_best.gro -p $topol -o emin.tpr
gmx_mpi mdrun -pin on -deffnm emin -ntomp $1 -plumed plumed_EMMI_emin.dat -c conf_best_emin.gro

# Once minimization is complete, we need to fix discontinuities due to Periodic Boundary Conditions with the following command:
plumed driver --plumed ${SCRIPT_DIR}/plumed_fix_pbc.dat --igro conf_best_emin.gro

# Now we convert conf_pbc.gro to conf_pbc.pdb. This file will contain only the heavy atoms used to generate the cryo-em map.
echo System-MAP-H | gmx_mpi trjconv -f conf_pbc.gro -s emin.tpr -n $ndx -o conf_pbc.pdb
