# Author: Eleanor Collier
# Date: August 22, 2018
# This script populates and runs the template .fsf files to preprocess rest scans
#
################################################################################----------
# USAGE: preproc_rest.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Scan session info
session="ses-emporientoinb" #name of session in BIDS file structure
RUNS="02 07 12" #runs to loop through

# Directories
PROJECT_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient #path to project
TEMPLATE_DIR=$PROJECT_DIR/scripts/templates #path to look for feat templates
PREP_DIR=$PROJECT_DIR/analysis/restPrep #path to output preprocessed data
DATA_DIR=$PROJECT_DIR/data/fMRI #path to look for raw data

# Settings
TR=1
TRIM=0
HFILTER=111
SMOOTH=6

################################################################################
main() {
  for subj in $subj_list; do
  	mk_template_dir
	  for r in $RUNS; do
  	  def_vars
  	  populate_fsf_script
  	  run_fsf_script &
  	  sleep 5
  	done
  done
  wait
}


# Make subject template directory
mk_template_dir() {
  sub_template_dir=$PREP_DIR/preprocessed/sub-${subj}
  if [ ! -d "$sub_template_dir" ]; then
  	mkdir -p $sub_template_dir
  fi
}


# Get subject/run-specific info for template
def_vars() {
  label="[SUBJECT $subj RUN ${r}:]"    
  anat_data=$DATA_DIR/sub-$subj/${session}/anat/*T1w_brain.nii.gz
  func_data=$DATA_DIR/sub-$subj/${session}/func/*run-${r}_bold.nii.gz
  output_dir=$PREP_DIR/preprocessed/sub-${subj}/rest_run${r}.feat
  nvols=$( fslnvols $func_data )
}


# Populate the preprocessing template
populate_fsf_script() {
  echo "${label} rendering the design template"
  cat $TEMPLATE_DIR/preproc.fsf \
    | sed "s|<<func_data>>|$func_data|g" \
	  | sed "s|<<anat_data>>|$anat_data|g" \
	  | sed "s|<<output_dir>>|$output_dir|g" \
	  | sed "s|<<nvols>>|$nvols|g" \
	  | sed "s|<<TR>>|$TR|g" \
	  | sed "s|<<trim>>|$TRIM|g" \
	  | sed "s|<<hfilter>>|$HFILTER|g" \
	  | sed "s|<<smooth>>|$SMOOTH|g" \
	  > $sub_template_dir/preproc_rest_run${r}.fsf
}


# If analysis has not been run, execute template in FEAT
run_fsf_script() {
  if [ ! -d "$output_dir" ]; then
  	echo "${label} running FEAT preprocessing"
	  feat $sub_template_dir/preproc_rest_run${r}.fsf
  else
	  echo "${label} epi has already been processed"
  fi
}


main "$@"
