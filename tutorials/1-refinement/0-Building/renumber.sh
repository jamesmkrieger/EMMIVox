# gro file
gro=$1
# pdb file
pdb=$2
# directory containing mdp
ref_dir=${3:-$(pwd)}
ref_dir=$(realpath "$ref_dir")
# output directory
out_dir=${4:-$(pwd)}
out_dir=$(realpath "$out_dir")
# top file
top=${5:-"$ref_dir/topol.top"}
echo $top

# rename old files
copied_gro=${out_dir}/old_$(basename "$gro")
copied_pdb=${out_dir}/old_$(basename "$pdb")
cp $gro $copied_gro
cp $pdb $copied_pdb

# create a fake tpr file
gmx_mpi grompp -f ${ref_dir}/../2-Equilibration/0-em-steep.mdp -c $copied_gro -p $top -o ${out_dir}/fake.tpr

# # convert old gro to new gro and pdb
echo 0 | gmx_mpi trjconv -f $copied_gro -o ${out_dir}/$(basename "$gro") -s ${out_dir}/fake.tpr
echo 0 | gmx_mpi trjconv -f $copied_gro -o ${out_dir}/$(basename "$pdb") -s ${out_dir}/fake.tpr

# # clean
rm ${out_dir}/fake.tpr
