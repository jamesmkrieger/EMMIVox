# number of replicas
nr=$1
# datadir
export DDIR=${2:-"../../1-refinement/4-Production/"}

export logfile=${3:-:"../../1-refinement/1-Map-Preparation/log.preprocess"}
export bestscalefile=${4:-"../../1-refinement/3-Map-Scaling/BEST_SCALE"}

export topol=${5:-"../../1-refinement/0-Building/topol.top"}
export ndx=${6:-"../../1-refinement/0-Building/index.ndx"}

export pdb=${7:-"../../1-refinement/3-Map-Scaling/step3_input_xtc.pdb"}
pdb=$(realpath --relative-to=. "$pdb")

export datafile=${9:-"../../1-refinement/1-Map-Preparation/emd_plumed_aligned.dat"}
datafile=$(realpath --relative-to=. "$datafile")

# 1) prepare master PLUMED input file
# extract NORM_DENSITY and RESOLUTION from `../1-Map-Preparation/log.preprocess`
# and BEST_SCALE from ../3-Map-Scaling/BEST_SCALE
n=`grep NORM_DENSITY $logfile | awk '{print $NF}'`
r=`grep Resolution $logfile | awk '{print $NF/10.0}'`
s=`grep BEST_SCALE $bestscalefile | awk '{print $NF}'`

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
# create master PLUMED file for production
sed -e "s/NORM_DENSITY_/$n/g" ${SCRIPT_DIR}/plumed_EMMI_template.dat \
  -e "s/RESOLUTION_/$r/g" -e "s/SCALE_/$s/g"  \
  -e "s|../../1-refinement/3-Map-Scaling/step3_input_xtc.pdb|$pdb|g" \
  -e "s|../../1-refinement/0-Building/index.ndx|$ndx|g" \
  -e "s|../../1-refinement/1-Map-Preparation/emd_plumed_aligned.dat|$datafile|g" > plumed_EMMI_1.dat

if [ "$not_homomer" -ne 0 ]; then
    # Comment out BFACT_NOCHAIN
    sed -e "s/BFACT_NOCHAIN/#BFACT_NOCHAIN/g" plumed_EMMI_1.dat > plumed_EMMI.dat
else
    cp plumed_EMMI_1.dat plumed_EMMI.dat
fi

rm plumed_EMMI_1.dat

# 2) prepare master EMMIStatus file
# Get line number of the frame with best score from COLVAR
line=`awk '{print NR, $0}' ${DDIR}/COLVAR | grep -v FIELDS | sort -n -k 3 | head -n 1 | awk '{print $1}'`
# Create EMMIStatus file header 
sed -n 1p ${DDIR}/EMMIStatus > EMMIStatus
# Number of Bfactors
nbf=`tail -n 1 ${DDIR}/EMMIStatus | awk '{print NF-3}'`
# Get minimum Bfactor from that line (skipping first three columns which are not Bfactor values)
a=`sed -n ${line}p ${DDIR}/EMMIStatus | awk '{for(i=4;i<=NF;++i)printf "%s\n",$i}' | sort -g | head -n 1`

# Fill EMMIStatus file with same bfactor
# Time scale and offset
echo 0 ${s} 0 | awk '{printf "%10.7e %10.7e %10.7e ",$1,$2,$3}' >> EMMIStatus
# Bfactors
for ((i=1; i<=${nbf};i++))
do
 echo ${a} | awk '{printf "%10.7e ",$1}' >> EMMIStatus
done
echo " " | awk '{printf "\n"}' >> EMMIStatus

# 3) Extract frames from the single structure refinement to use as initial frames for production
frames=`tail -n 1 ${DDIR}/COLVAR | awk '{printf "%d\n",$1}'`
f0=`echo $frames | awk '{printf "%d\n",$1/2}'`
stride=`echo $frames $nr | awk '{printf "%d\n",$1/$2/2}'`

# now prepare one directory per replica and put what is needed inside
for d in `seq 0 $(( $nr - 1 ))`
do
  # add trailing zero
  dd=$(printf "%02d" $d)
  # create directory
  mkdir rep-${dd}
  # extract initial conformation
  val=$(( $f0 + $d * $stride ))
  # chose whole system
  echo 0 | gmx_mpi trjconv -f ${DDIR}/production.trr -o rep-${dd}/conf.gro -dump ${val} -s ${DDIR}/production.tpr
  # create tpr file
  gmx_mpi grompp -f 0-nvt-production.mdp -c rep-${dd}/conf.gro -n $ndx -p $topol -o rep-${dd}/production.tpr
  # copy master PLUMED and EMMIStatus file into replica directory
  cp plumed_EMMI.dat EMMIStatus rep-${dd}/
done
