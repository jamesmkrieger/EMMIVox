# gro file
gro=$1
# pdb file
pdb=$2
# directory
dir={$3:-$pwd}

# rename old files
cp ${dir}/$gro ${dir}/old_$gro
cp ${dir}/$pdb ${dir}/old_$pdb

# create a fake tpr file
gmx_mpi grompp -f ${dir}../2-Equilibration/0-em-steep.mdp -c ${dir}/old_$gro -p ${dir}/topol.top -o ${dir}/fake.tpr

# convert old gro to new gro and pdb
echo 0 | gmx_mpi trjconv -f ${dir}/old_$gro -o ${dir}/$gro -s ${dir}/fake.tpr
echo 0 | gmx_mpi trjconv -f ${dir}/old_$gro -o ${dir}/$pdb -s ${dir}/fake.tpr

# clean
rm ${dir}/fake.tpr
