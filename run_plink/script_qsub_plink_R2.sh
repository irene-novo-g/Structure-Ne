#Script RUN plink
#!/bin/bash
#$ -cwd

rm script_qsub_plink.sh.*

################## INPUT FILE AND REPLICATES AS ARGUMENTS ############

#Check number of arguments
if [ $# -ne 3 ]  
then
	echo "Usage: $0 <dataBP> <REPS> <n>" 
	exit 1
fi

#Set arguments
dataBP=$1
REPS=$2
n=$3

########################################################

module load gsl/2.1
#Working directory
WDIR=$PWD 

#Scratch directory
mkdir -p /state/partition1/NataliaSIM$n/$SLURM_JOBID/


#File with information of node and directory
touch $WDIR/$SLURM_JOBID.`hostname`.`date +%HH%MM`

###################### TRANSFER TO SCRATCH ########################

cp /home/invitado2/NATALIA/N1000/50c_inver/$dataBP1.map /state/partition1/NataliaSIM$n/$SLURM_JOBID/
cp /home/invitado2/NATALIA/N1000/50c_inver/$dataBP1.ped /state/partition1/NataliaSIM$n/$SLURM_JOBID/

cp plink /state/partition1/NataliaSIM$n/$SLURM_JOBID/


cd /state/partition1/NataliaSIM$n/$SLURM_JOBID

################################ REPLICATES #############################
for ((r=1; r<=$REPS; r++))
do


######################## PLINK #########################


./plink --file dataBP2 --r2 --ld-window 2 --out temp_2

cp -r /state/partition1/NataliaSIM$n/$SLURM_JOBID/R2${r}.ld $WDIR/


done

awk '{print $5 " " $7}' temp_2.ld > R2_2

######################## SCRATCH CLEANING #########################

rm $WDIR/$SLURM_JOBID.* 2> /dev/null
rm -rf /state/partition1/NataliaSIM$n/$SLURM_JOBID/ 2> /dev/null



