# Author: Eleanor Collier
# Date: August 1, 2018
# This script unzips all nifti files in all specified subject folders
################################################################################----------
#USAGE: unzip_files.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Directories, files & parameters to change
DATA_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/data/fMRI #where to look for raw data
SESSION="ses-emporientoinb" #name of session in BIDS file structure, leave as "" if none

################################################################################
main() {
  for subj in $subj_list; do
  	unzip_anat &
  	unzip_func &
  done
  wait
}


#Unzip anatomical nifti file
unzip_anat() {
  ls -1 $DATA_DIR/sub-${subj}/${SESSION}/anat/*.nii.gz > /dev/null 2>&1
  if [ "$?" = "0" ]; then
	  gunzip $DATA_DIR/sub-${subj}/${SESSION}/anat/*.nii.gz
	  echo "Unzipping anatomical niftis for subject $subj"
  fi
}


#Unzip functional nifti files
unzip_func() {
  ls -1 $DATA_DIR/sub-${subj}/${SESSION}/func/*.nii.gz > /dev/null 2>&1
  if [ "$?" = "0" ]; then
  	for runfile in $DATA_DIR/sub-${subj}/${SESSION}/func/*.nii.gz; do
  	  gunzip $runfile &
  	done
  	echo "Unzipping functional niftis for subject $subj"
  fi
}


main "$@"
