# Author: Eleanor Collier
# Date: August 23, 2018
# This script runs the FSL tissue segmentation tool (FAST) on anatomical images 
# of specified subjects
################################################################################----------
# USAGE: segment_tissue.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
session="ses-emporientoinb" #name of session in BIDS file structure
DATA_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/data/fMRI #path to look for raw data

################################################################################
main() {
  for subj in $subj_list; do
    def_vars
    chop_brains &
    sleep 2
  done
  wait
}


# Define subject-specific info
def_vars() {
  label="[SUBJECT $subj:]"    
  output_dir=$DATA_DIR/sub-${subj}/${session}/anat/
}


# Run FAST tissue segmentation
chop_brains() {
  echo "${label} performing FAST tissue segmentation"
	fast $output_dir/sub-${subj}_${session}_T1w_brain.nii.gz
  cleanup
}


# Delete extraneous output files and rename CSF & WM files 
cleanup() {
  echo "${label} deleting and renaming output files"
  pushd "${output_dir}" >/dev/null
	rm *mixeltype.nii.gz *seg.nii.gz *1.nii.gz
	mv *brain_pve_0.nii.gz sub-${subj}_${session}_T1w_brain_CSF.nii.gz
	mv *brain_pve_2.nii.gz sub-${subj}_${session}_T1w_brain_WM.nii.gz
	popd
}


main "$@"
