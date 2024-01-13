# Author: Eleanor Collier
# Date: July 23, 2018
# This script runs the FSL brain extraction tool (BET) on anatomical images of 
# specified subjects
################################################################################----------
# USAGE: strip_skulls.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
SESSION="ses-syncspeak" #name of session in BIDS file structure, leave as "" if none
DATA_DIR=/home/ecollier/SyncDisclosures #path to look for raw data
FIT=0.35 # Fractional intensity threshold (smaller values give larger brain outline estimates; 0.35 is a good start)

################################################################################
main() {
  for subj in $subj_list; do
    def_vars
    strip_skulls &
    sleep 2
  done
  wait
}

def_vars() {
  label="[SUBJECT $subj:]"
  output_dir=$DATA_DIR/sub-$subj/${SESSION}/anat
}


strip_skulls() {
  echo "${label} performing BET skull stripping"
  bet $output_dir/sub-${subj}_${SESSION}_T1w.nii.gz \
      $output_dir/sub-${subj}_${SESSION}_T1w_brain \
	      -m -B -f $FIT
}


main "$@"
