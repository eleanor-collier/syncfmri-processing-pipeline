# Author: Eleanor Collier
# Date: August 22, 2018
# This script populates and runs the template .fsf files to preprocess fMRI scans
# (Note: Make sure the path to the standard image is correct in preproc.fsf)
################################################################################----------
# USAGE: preproc.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Scan session info
SESSION="ses-syncspeak" #name of session in BIDS file structure, leave as "" if none
TASKS={pos1,pos2,neg1,neg2} #task runs to loop through (content in brackets will be permuted)
# TASKS Usage: For speaking sessions, use the following format: {pos1,pos2,neg1,neg2}
# For listening sessions, use the following format: {speaker#,speaker#,speaker#,speaker#}{pos1,pos2,neg1,neg2}
# If there is only one speaker, remove the brackets around speaker#

# Directories
PROJECT_DIR=/home/ecollier/SyncDisclosures #path to project
TEMPLATE_DIR=$PROJECT_DIR/code/templates #path to look for feat templates
PREP_DIR=$PROJECT_DIR/analysis/prep #path to output preprocessed data
DATA_DIR=$PROJECT_DIR #path to look for raw data

# Data info
UNWARPING_APPLIED=1 #was unwarping applied to the data beforehand? 1=yes, 0=no

# Settings
TR=1.5
TRIM=0
HFILTER=111
SMOOTH=6

################################################################################
main() {
  for subj in $subj_list; do
  	mk_template_dir
	  for t in $(eval echo $TASKS); do
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
  sub_template_dir=$PREP_DIR/preprocessed/sub-${subj}/${SESSION}
  if [ ! -d "$sub_template_dir" ]; then
  	mkdir -p $sub_template_dir
  fi
}


# Get subject/run-specific info for template
def_vars() {
  label="[SUBJECT $subj RUN ${t}:]"    
  anat_data=$DATA_DIR/sub-$subj/${SESSION}/anat/*T1w_brain.nii.gz

  # If unwarping was applied, add suffix "_unwarped to func data"
  if [ UNWARPING_APPLIED = 1 ]; then func_suffix="_unwarped"; 
  elif [ UNWARPING_APPLIED = 0 ]; then func_suffix=""; fi
  func_data=$DATA_DIR/sub-$subj/${SESSION}/func/*task-${t}*bold${func_suffix}.nii.gz

  output_dir=$PREP_DIR/preprocessed/sub-${subj}/${SESSION}/${t}.feat
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
	  > $sub_template_dir/preproc_${t}.fsf
}


# If analysis has not been run, execute template in FEAT
run_fsf_script() {
  if [ ! -d "$output_dir" ]; then
  	echo "${label} running FEAT preprocessing"
	  feat $sub_template_dir/preproc_${t}.fsf
  else
	  echo "${label} epi has already been processed"
  fi
}


main "$@"
