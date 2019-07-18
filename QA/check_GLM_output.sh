# Author: Eleanor Collier
# Date: July 23, 2018
# This script checks whether subjects' functional data was successfully 
# preprocessed/cleaned
################################################################################----------
# USAGE: check_output_rest.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
RUNS="02 07 12" #run numbers of runs to check
PREP_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/analysis/restPrep/cleaned #path to cleaned data
FINAL_FUNC_DATA=res4d.nii.gz #name of cleaned data

################################################################################
main() {
  for subj in $subj_list; do
    for r in $RUNS; do
      def_vars
      check_output
    done
  done
}


def_vars() {
  label="[SUBJECT $subj RUN ${r}:]"
  run_dir=$PREP_DIR/sub-$subj/rest_run${r}.feat
  output_file=$run_dir/stats/$FINAL_FUNC_DATA
}


check_output() {
  if [[ -d $run_dir ]]; then
    if [[ ! -f $output_file ]]; then
      echo "${label} $FINAL_FUNC_DATA not found...
                     Remove run ${r} folder and start over? [y for yes, n for no]"
      read remove
      if [[ $remove == y ]]; then
        rm -rf $run_dir
        echo "${label} Ready to redo data cleaning"
      elif [[ $remove == n ]]; then
        echo "${label} Don't foget to remove rest_run${r}.feat before reprocessing!"
      fi
    fi
  else
    echo "${label} rest_run${r}.feat folder does not exist"
  fi
}


main "$@"
