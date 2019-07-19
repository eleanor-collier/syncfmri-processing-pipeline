  # Author: Eleanor Collier
# Date: August 26, 2018
# Clean nuisance regressors from EPI to get residuals for ROI time course extraction
#
################################################################################----------
# USAGE: clean_nuisance_rest.sh 01 02 03 ...
################################################################################----------

subj_list="$@"

# Scan session info
RUNS="02 07 12" #runs to loop through

# Directories
PROJECT_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient #path to project
TEMPLATE_DIR=$PROJECT_DIR/scripts/templates #path to look for feat templates
PREP_DIR=$PROJECT_DIR/analysis/restPrep #path to look for preprocessed data
DATA_DIR=$PROJECT_DIR/data/fMRI #path to look for raw data

# Settings
TR=1
HFILTER=111
TEMPFILT=1
TEMPDERIV=1

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
  sub_template_dir=$PREP_DIR/cleaned/sub-${subj}
  if [ ! -d "$sub_template_dir" ]; then
    mkdir -p "$sub_template_dir"
  fi
}


# Get subject/run-specific info for template
def_vars() {
  label="[SUBJECT $subj RUN ${r}:]"    
  preproc_dir="${PREP_DIR}/preprocessed/sub-${subj}/rest_run${r}.feat"
  output_dir="${PREP_DIR}/cleaned/sub-${subj}/rest_run${r}.feat"
  func_data="$preproc_dir/filtered_func_data.nii.gz"
  nuisance_dir="$preproc_dir/nuisance"
  mc_dir="${nuisance_dir}/mc"
  mo_dir="${nuisance_dir}/mo"
  nvols=$( fslnvols $func_data )
}
  

# Populate the glm template
populate_fsf_script() {
  echo "${label} rendering the design template"
  cat $TEMPLATE_DIR/clean_nuisance.fsf \
    | sed "s|<<func_data>>|$func_data|g" \
    | sed "s|<<output_dir>>|$output_dir|g" \
    | sed "s|<<TR>>|${TR}|g" \
    | sed "s|<<nvols>>|$nvols|g" \
    | sed "s|<<hFilter>>|${HFILTER}|g" \
    | sed "s|<<tempFilt>>|${TEMPFILT}|g" \
    | sed "s|<<tempDeriv>>|${TEMPDERIV}|g" \
    | sed "s|<<MOTION1>>|${mc_dir}/motion1.par|g" \
    | sed "s|<<MOTION2>>|${mc_dir}/motion2.par|g" \
    | sed "s|<<MOTION3>>|${mc_dir}/motion3.par|g" \
    | sed "s|<<MOTION4>>|${mc_dir}/motion4.par|g" \
    | sed "s|<<MOTION5>>|${mc_dir}/motion5.par|g" \
    | sed "s|<<MOTION6>>|${mc_dir}/motion6.par|g" \
    | sed "s|<<OUTLIERS>>|${mo_dir}/outliers.txt|g" \
    | sed "s|<<WM>>|${nuisance_dir}/WM_meants.txt|g" \
    | sed "s|<<CSF>>|${nuisance_dir}/CSF_meants.txt|g" \
    | sed "s|<<GLOBAL>>|${nuisance_dir}/WB_meants.txt|g" \
    > $sub_template_dir/clean_rest_run${r}.fsf
}


# If analysis has not been run, execute template in FEAT
run_fsf_script() {
  if [ ! -d "$output_dir" ]; then   
    echo "${label} starting FEAT cleaning"
    feat $sub_template_dir/clean_rest_run${r}.fsf
    sleep 10
  else
    echo "${label} EPI has already been cleaned"
  fi
}


main "$@"
