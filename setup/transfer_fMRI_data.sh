# Author: Eleanor Collier
# Date: April 12, 2023
# Copies one subject's brain data from SNLNAS to UCR CAN Cluster
################################################################################----------
#USAGE: transfer_fMRI_data.sh subj_id
################################################################################----------

subj_list=$@ #Example: 01 02 03

# Directories, files & parameters to change
GET_DATA_HERE="/Volumes/Research Project/Eleanor/SyncDisclosures_fMRI/Imaging/" #data folder on SNLNAS
SEND_DATA_HERE=/home/ecollier/SyncDisclosures #data folder on CAN Cluster
CAN_LOGIN=ecollier@master1-can.ucr.edu #replace with your login name before @
SESSION=ses-syncspeak #name of session in BIDS file structure, leave as "" if none

################################################################################
main() {
  for subj in $subj_list; do
    def_vars
    if [[ `ssh ${CAN_LOGIN} test -d ${destination_folder} && echo exists` ]] ; then
      transfer_files &
      sleep 1
    else
      echo "${LABEL} data already exists"
    fi
  done
  wait
}

def_vars() {
  LABEL="[SUBJECT ${subj} SESSION ${SESSION}:]"
  origin_folder="${GET_DATA_HERE}/sub-${subj}/${SESSION}"
  destination_folder="${SEND_DATA_HERE}/sub-${subj}/${SESSION}"
}


# Transfer files from Rolando to Discovery: EDIT scan names
transfer_files() {
	echo "${LABEL} transfering brain data"
	scp -r "${origin_folder}" "${CAN_LOGIN}:${destination_folder}"
}


main "$@"
