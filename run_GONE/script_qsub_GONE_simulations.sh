#script_qsub_GONE_simulations.sh
#!/bin/bash
#$ -cwd

rm script_qsub_GONE_simulations.sh.*

########################################################

#Check number of arguments
if [ $# -ne 2 ]  
then
	echo "Usage: $0 <FILE> <d>" 
	exit 1
fi

### Set arguments

FILE=$1  ### Data file name
d=$2     ### Directory number

### Take input parameters from file INPUT_PARAMETERS_FILE_SIM

source INPUT_PARAMETERS_FILE_SIM

###################### FILES NEEDED ########################

### chromosome$n.ped
### chromosome$n.map

### EXECUTABLES FILES NEEDED IN DIRECTORY PROGRAMMES:

### LD_SNP_REAL3
### SUMM_REP_CHROM3
### GONE (needs gcc/7.2.0)
### GONEaverages
### GONEparallel.sh

################### Remove previous output files ##################

#Working directory
WDIR=$PWD 

#Output directory
if [ -d "$WDIR/OUTPUT_GONE_$FILE" ]
then
rm -r $WDIR/OUTPUT_GONE_$FILE
fi

mkdir -p $WDIR/OUTPUT_GONE_$FILE

#Scratch directory
mkdir -p /state/partition1/LD_BURROWS$d/$SLURM_JOBID/
mkdir -p /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES

###################### TRANSFER TO SCRATCH ########################

cp chromosome* /state/partition1/LD_BURROWS$d/$SLURM_JOBID/
cp INPUT_PARAMETERS_FILE_SIM /state/partition1/LD_BURROWS$d/$SLURM_JOBID/
cp ../../PROGRAMMES/LD_SNP_REAL3 /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES/
cp ../../PROGRAMMES/SUMM_REP_CHROM3 /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES/
cp ../../PROGRAMMES/GONE /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES/
cp ../../PROGRAMMES/GONEaverage /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES/
cp ../../PROGRAMMES/GONEparallel.sh /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PROGRAMMES/

touch $WDIR/$SLURM_JOBID.`hostname`.`date +%HH%MM`
cd /state/partition1/LD_BURROWS$d/$SLURM_JOBID

################### LOOP CHROMOSOMES ##################
### Analysis of linkage disequilibrium in windows of genetic
### distances between pairs of SNPs for each chromosome

if [ $maxNCHROM != -99 ]
then
NCHR=$maxNCHROM
fi

echo "START ANALYSIS OF CHROMOSOMES" > timefile

options_for_LD="$SAM $MAF $PHASE $NGEN $NBIN $ZERO $DIST $cMMb"

if [ $threads -eq -99 ]
then
threads=$(getconf _NPROCESSORS_ONLN)
fi

#cp chromosome* $WDIR/OUTPUT_GONE_$FILE/

###### LD_SNP_REAL3 #######

### Obtains values of c, d2, etc. for pairs of SNPs in bins for each chromosome
for ((n=1; n<=$NCHR; n++)); do echo $n; done | xargs -I % -P $threads bash -c "./PROGRAMMES/LD_SNP_REAL3 % $options_for_LD"

######################## SUMM_REP_CHROM3 #########################
### Combination of all data gathered from chromosomes into a single output file

### Adds results from all chromosomes

for ((n=1; n<=$NCHR; n++))
do
cat outfileLD$n >> CHROM
echo "CHROMOSOME $n" >> PARAMETERS
sed '2,3d' outfileLD$n > temp
mv temp outfileLD$n
cat parameters$n >> PARAMETERS
done

#mv outfileLD* $WDIR/OUTPUT_GONE_$FILE/
rm parameters*

./PROGRAMMES/SUMM_REP_CHROM3<<@
$NGEN	NGEN
$NBIN	NBIN
$NCHR	NCHR
@

#mv chrom* $WDIR/OUTPUT_GONE_$FILE/

cat PARAMETERS >> PARAMETERS_$FILE
echo -e "\n" >> PARAMETERS_$FILE
echo "INPUT FOR GONE" >> PARAMETERS_$FILE
echo -e "\n" >> PARAMETERS_$FILE
cat outfileLD >> PARAMETERS_$FILE

rm PARAMETERS
rm CHROM

############################# GONE.cpp ##########################
### Obtain estimates of temporal Ne from GONE

echo "Running GONE" >> timefile
START=$(date +%s)

./PROGRAMMES/GONEparallel.sh -hc $hc outfileLD $REPS

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "GONE run took $DIFF seconds" >> timefile

echo "END OF ANALYSES" >> timefile

rm outfileLD

cp -r /state/partition1/LD_BURROWS$d/$SLURM_JOBID/outfileLD_Ne_estimates $WDIR/Ne_$FILE
cp -r /state/partition1/LD_BURROWS$d/$SLURM_JOBID/outfileLD_d2_sample $WDIR/d2_$FILE
cp -r /state/partition1/LD_BURROWS$d/$SLURM_JOBID/outfileLD_TEMP $WDIR/OUTPUT_GONE_$FILE/
cp -r /state/partition1/LD_BURROWS$d/$SLURM_JOBID/PARAMETERS_$FILE $WDIR/

######################## SCRATCH CLEANING #########################

rm $WDIR/$SLURM_JOBID.* 2> /dev/null
rm -rf /state/partition1/LD_BURROWS$d/$SLURM_JOBID/ 2> /dev/null

###################################################################















