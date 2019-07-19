# Author: Eleanor Collier
# Date: February 18, 2019
# Copies one subject's brain data from Rolando to Discovery and renames 
# subject ID in filenames
################################################################################----------
#USAGE: transfer_fMRI_data.sh dbic_id subj_id
################################################################################----------

dbic_id=$1 #Example: sid001413
subj_id=$2 #Example: 02

# Directories, files & parameters to change
GET_DATA_HERE=/inbox/BIDS/Meyer/Eleanor/1033-emporient/sub-${dbic_id} #subject folder on Rolando
SEND_DATA_HERE=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/data/sub-${subj_id} #subject folder on Discovery
ROLANDO_LOGIN=ecollier@rolando.cns.dartmouth.edu #replace with your login name before @
SESSION="ses-emporientoinb" #name of session in BIDS file structure, leave as "" if none

LABEL="[SUBJECT ${subj_id}:]"

################################################################################
main() {
  if [ ! -d $SEND_DATA_HERE ]; then
    transfer_files
    rename_files
  else
    echo "${LABEL} data already exists"
  fi
}


# Transfer files from Rolando to Discovery: EDIT scan names
transfer_files() {
	echo "${LABEL} transfering brain data"
	scp -r "${ROLANDO_LOGIN}:${GET_DATA_HERE}" "${SEND_DATA_HERE}"
}
      

rename_files() {
  echo "${LABEL} renaming data files"
  pushd "${SEND_DATA_HERE}" >/dev/null
  #Rename files in main subject folder
  for file in ${SESSION}/sub-$dbic_id*; do 
	mv "$file" "${file/$dbic_id/$subj_id}"; 
  done
  #Rename files in subject's scan folders
  for file in ${SESSION}/*/sub-$dbic_id*; do 
  	mv "$file" "${file/$dbic_id/$subj_id}";
  done
  #Rename subject's anatomical files
  for file in ${SESSION}/anat/*; do
  	mv "$file" "${file/_acq-MPRAGE/}"; 
  done
  wait
  popd
}


main "$@"
