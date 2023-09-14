#Script RUN plink
#!/bin/bash
#$ -cwd

#rm script_qsub_plink_Remove_Inversion.sh.*

################## INPUT FILE AND REPLICATES AS ARGUMENTS ############

#Check number of arguments
if [ $# -ne 2 ]  
then
	echo "Usage: $0 <REPS> <n>" 
	exit 1
fi

#Set arguments
REPS=$1
n=$2

########################################################

module load gsl/2.1
#Working directory
WDIR=$PWD 

#Scratch directory
mkdir -p /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/

#File with information of node and directory
touch $WDIR/$SLURM_JOBID.`hostname`.`date +%HH%MM`

###################### TRANSFER TO SCRATCH ########################

cp dataBP* /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/
cp /home/armando2/GONE/TFG_NATALIA/range_inver /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/
cp ../PROGRAMMES/plink /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/

cd /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID

################################ REPLICATES #############################
for ((r=1; r<=$REPS; r++))
do

######################## PLINK #########################

./plink --file dataBP${r} --exclude range range_inver --recode --out noinver${r}

cp -r /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/noinver${r}.map $WDIR/
cp -r /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/noinver${r}.ped $WDIR/

done

######################## SCRATCH CLEANING #########################

rm $WDIR/$SLURM_JOBID.* 2> /dev/null
rm -rf /state/partition1/TFGNataliaSIM$n/$SLURM_JOBID/ 2> /dev/null



