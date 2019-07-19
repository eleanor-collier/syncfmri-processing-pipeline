# Author: Eleanor Collier
# Date: August 1, 2018
# This script zips all nifti files in all specified subject folders
################################################################################----------
#USAGE: zip_files.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
DATA_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/data/fMRI #where to look for raw data
SESSION="ses-emporientoinb" #name of session in BIDS file structure, leave as "" if none

################################################################################
main() {
  for subj in $subj_list; do
  	zip_anat &
  	zip_func &
  done
  wait
}


#Zip anatomical nifti file
zip_anat() {
  ls -1 $DATA_DIR/sub-${subj}/${SESSION}/anat/*.nii > /dev/null 2>&1
  if [ "$?" = "0" ]; then
  	gzip $DATA_DIR/sub-${subj}/${SESSION}/anat/*.nii
  	echo "Zipping anatomical niftis for subject $subj"
  fi
}


#Zip functional nifti files
zip_func() {
  ls -1 $DATA_DIR/sub-${subj}/${SESSION}/func/*.nii > /dev/null 2>&1
  if [ "$?" = "0" ]; then
  	for runfile in $DATA_DIR/sub-${subj}/${SESSION}/func/*.nii; do
  	  gzip $runfile &
  	done
  	echo "Zipping functional niftis for subject $subj"
  fi
}


main "$@"