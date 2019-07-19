# Author: Eleanor Collier
# Date: May 17, 2019
# This script checks for excessive motion outliers from 
# make_nuisance.sh output
################################################################################----------
# USAGE: check_motion_rest.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
RUNS="02 07 12" #run numbers of runs to check
PREP_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/analysis/restPrep/preprocessed #path to preprocessed data
MOTION_DATA=outliers.txt #name of motion outlier file
MAX_OUTLIERS=90 #if a run has more than this many motion outliers, the script will flag it

################################################################################
main() {
  for subj in $subj_list; do
    for r in $RUNS; do
      def_vars
      check_motion
    done
  done
}


def_vars() {
  label="[SUBJECT $subj RUN ${r}:]"
  run_dir=$PREP_DIR/sub-$subj/rest_run${r}.feat
  motion_file=$run_dir/nuisance/mo/$MOTION_DATA
}


check_motion() {
  if [[ -d $run_dir ]]; then
    if [[ -f $motion_file ]]; then
      num_outliers=$( grep -c 1 $motion_file )
      if (( $num_outliers > $MAX_OUTLIERS )); then
      	echo "${label} ${num_outliers} motion outliers detected; data should not be used"
  	  fi
   	else
      echo "${label} $MOTION_DATA not found"
    fi
  else
    echo "${label} rest_run${r}.feat folder does not exist"
  fi
}


main "$@"
