# syncfmri-processing-pipeline
FSL pipeline to preprocess fMRI data for neural synchrony analysis and extract ROI time courses. Works with BIDS format data. Scripts are written in bash. Scripts can be used to run batches of subjects on the computing cluster at UCR's Center for Advanced Neuroimaging (CAN).

*Follow steps below carefully.*

## Before Beginning Pipeline
1. Copy this repository to your project's code folder on the cluster
   * To log into cluster via terminal: ```ssh -Y username@master1-can.ucr.edu```
2. Edit all scripts with your desired directories & project names where prompted at the top of the script
3. If you're running these scripts locally on a mac, you may get strange "command not found" errors at first. If that's the case, you may need to convert each script to unix format using the command ```dos2unix scriptname.sh```
4. Run ```setup/convert_dicom_to_nifti.sh```
    * Converts dicom files to zipped nifti files using dcm2bids, which implements dcm2niix under the hood
    * Script handles one subject and one session at a time (assuming multiple sessions per subject)
    * Requires installation of dcm2bids and dcm2niix
    * Generates BIDS-compliant json files and organizes data into a BIDS-compliant folder structure according to the details specified in a given config.json file
      * config.json files are contained within the bids_config folder. For more details on how to set one up, see this tutorial on Andy's Brain Blog: https://andysbrainbook.readthedocs.io/en/latest/OpenScience/OS/BIDS_Overview.html
    * Dicom files should first be stored in a subfolder of the main project folder called sourcedata
5. Run ```setup/transfer_fMRI_data.sh``` for each subject:
    * Transfers data from folder on SNL NAS to study folder on UCR CAN cluster
    * You will be prompted for your CAN cluster password
    * Script handles one subject at a time
6. Make sure FSL is loaded before running the following scripts


## Pipeline Steps
1. Run ```1_strip_skulls.sh```
    * Strips skull/non-brain matter from anatomical image
    * Adjust the FIT parameter which controls how much matter gets stripped; you may want to record this value somewhere
    * After running script, inspect each subject's anatomical image in fslview to ensure no loss of PFC (too much stripped) or excess dura around brain (too little stripped), then adjust FIT parameter as needed and re-run script until you like the results
    * It may be easiest to first run all subjects with a ballpark FIT parameter (~0.35), then tweak it for each subject individually as needed
    * If running on cluster, cluster can handle all subjects in one job
2. Run ```2_segment_tissue.sh```
    * Generates white matter & CSF volumes from anatomical images for later use in making nuisance regressors
    * If running on cluster, cluster can handle all subjects in one job
3. Run ```3_unwarp.sh```
    * Creates merged fieldmap from AP/PA EPIs using ```topup```
    * Uses merged fieldmap to unwarp magnetic field inhomogeneities in functional runs using ```applytopup```
    * A good explanation of this process can be found here: https://andysbrainbook.readthedocs.io/en/stable/FrequentlyAskedQuestions/FrequentlyAskedQuestions.html#unwarping-with-blip-up-blip-down-images
4. Run ```4_preproc.sh```
    * Applies the following preprocessing steps to EPIs for all runs specified in script using FEAT:
      * removal of low-frequency noise below 0.009 Hz with a high-pass filter
      * estimation of head motion using MCFLIRT
      * skull-stripping using BET
      * spatial smoothing with a 6mm radius
      * registration to the anatomical image using BBR
    * Parameters can be tweaked if needed
    * Fills out a copy of templates/preproc.fsf for each subject & run, which is then used by FEAT to preprocess the data
      * Make sure to edit preproc.fsf such that the path to the standard anatomical image (MNI152_T1_2mm_brain) is correct! You can figure out where FSL's standard images are stored by opening the fsleyes GUI and selecting File > Add standard, then checking the path to the directory that pops up.
    * Once the script finishes, FEAT will still be running in the background. You'll know FEAT is done when you see a file called "filtered_func.nii.gz" in the main output folder and "standard2highres.mat" in the reg folder. Wait to move on until FEAT has finished.
    * It's a good idea to check that registration was successful and that head motion wasn't egregiously high. Tutorial on how to do so here: https://andysbrainbook.readthedocs.io/en/latest/fMRI_Short_Course/Preprocessing/Checking_Preprocessing.html
    * If running on cluster, cluster can handle all subjects in one job
5. Run ```5_make_nuisance.sh```
    * Creates the following nuisance regressors from preprocessed EPIs for all runs specified in script
      * 6 motion parameters
      * motion outliers
      * CSF signal
      * White matter signal
      * Global brain signal
    * Nuisance regressors can be omitted or included as needed
    * If running on cluster, cluster can handle UP TO 25 RUNS PER JOB (so if each subject has 3 runs, run max 8 subjects per job)
    * To check for subjects you may want to exclude from analysis due to too many motion outliers, run QA/check_motion_outliers.sh
6. Run ```6_clean_nuisance.sh```
    * Regresses out above nuisance variables in GLM & scrubs motion outliers
    * Fills out a copy of templates/preproc.fsf for each subject & run, which is then used by FEAT to clean the data
    * If running on cluster, cluster can handle UP TO 25 RUNS PER JOB (so if each subject has 3 runs, run max 8 subjects per job)
    * To check that cleaned EPIs were successfully output, run QA/check_GLM_output
7. Run ```7_extract_roi_timecourses.sh```
    * Extracts activation time courses from each roi in every subdirectory of the ROIs folder
    * If running on cluster, cluster can handle only 10 RUNS PER JOB. Do NOT try to run more or you will start crashing nodes
