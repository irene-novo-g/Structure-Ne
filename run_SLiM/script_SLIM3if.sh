#Script RUN SLIM3
#!/bin/bash
#$ -cwd

rm script_SLIM3if.sh.*

################## INPUT FILE AND REPLICATES AS ARGUMENTS ############

#Check number of arguments
if [ $# -ne 4 ]  
then
	echo "Usage: $0 <slim3INPUTfile> <NIND> <REPS> <n>" 
	exit 1
fi

#Set arguments
INPUT=$1
NIND=$2
REPS=$3
n=$4

########################################################

module load gsl/2.1

#Working directory
WDIR=$PWD
mkdir -p RESULTS$INPUT

#Scratch directory
mkdir -p /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/

#File with information of node and directory
touch $WDIR/$SLURM_JOBID.`hostname`.`date +%HH%MM`

###################### TRANSFER TO SCRATCH ########################

cp $INPUT /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/
cp ../PROGRAMMES/READSLIMOUT3_SLIM3 /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/

cd /state/partition1/TFGPilarSIM$n/$SLURM_JOBID

################################ REPLICATES #############################

for ((r=1; r<=$REPS; r++))
do

################################ SLIM3 #############################

module load SLiM/3.3.2

START=$(date +%s)
slim $INPUT > slimout
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Slim3 took 		$DIFF seconds" > timefile

if [[ ${r} -eq 1 ]]
then
#cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/slimout $WDIR/RESULTS$INPUT/slimout$r
cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/timefile $WDIR/RESULTS$INPUT/timefile_slim_$r
fi

################################ READSLIMOUT3_SLIM3 #############################

START=$(date +%s)
./READSLIMOUT3_SLIM3<<@
$NIND
250000000
1
1
@
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "READSLIMOUT3_SLIM3 took 		$DIFF seconds" > timefile

cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/dataBP.map $WDIR/RESULTS$INPUT/chromosome$r.map
cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/dataBP.ped $WDIR/RESULTS$INPUT/chromosome$r.ped
#cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/list_allsnps $WDIR/RESULTS$INPUT/list_allsnps$r
#cp -r /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/timefile $WDIR/timefile$r

done

######################## SCRATCH CLEANING #########################

rm $WDIR/$SLURM_JOBID.* 2> /dev/null
rm -rf /state/partition1/TFGPilarSIM$n/$SLURM_JOBID/ 2> /dev/null



