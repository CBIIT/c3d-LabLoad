/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Mar 18, 2013                                                  */
/* Description: This is a DE-installation script for the CDW Lab Loader. */
/*              It is intened to be used prior to the Full Lab Loader    */
/*              installation (LabLoader_Full_to_v1.0.4) procedures.      */

Set Timing off verify off

-- Spool a log file
spool UNINSTALL_Lab_Loader.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

-- DROP SEQUENCES
Prompt ...Dropping Sequences
Drop sequence NLB_SEQ
/

--DROP TABLES
Prompt ...Dropping Tables
Drop table BDL_TEMP_FILES
/

Drop Table CDW_LAB_RESULTS
/

Drop Table CDW_LAST_LOAD
/

Drop Table GU_LAB_RESULTS_HOLD
/

Drop Table GU_LAB_RESULTS_STAGE
/

Drop Table MIS_CDR_TESTS
/

Drop Table MIS_LAB_RESULTS_HISTORY
/

Drop Table MDLABS_STG
/

Drop Table MDLABS_HOLD
/

Drop Table NCI_INVALID_LABTESTS
/

Drop Table NCI_INVALID_RESULTS
/

Drop Table NCI_LABS
/

Drop Table NCI_LABS_ERROR_LABS
/

Drop Table NCI_LABS_MANUAL_LOAD_STAGE
/

Drop Table NCI_LABS_MANUAL_LOAD_HOLD
/

Drop Table NCI_LAB_LOAD_CTL
/

Drop Table NCI_LAB_MAPPING
/

Drop Table NCI_LAB_VALID_PATIENTS
/

Drop Table NCI_STUDY_LABDCM_EVENTS_TB
/

Drop Table NCI_UOM_MAPPING
/

Drop Table NCI_UPLOAD_SYBASE_LAB_RESULTS
/

Drop Table NCI_LAB_LOAD_PATIENT_LOAD
/

Drop Table BDL_RESPONSE_REPEATS
/

Drop Table NCI_STUDY_PATIENT_IDS
/

Drop Table NCI_STUDY_PATIENT_IDS_CTL
/

Drop Table NCI_LABS_AUTOLOAD_HOLD
/

Drop Table NCI_LABS_MANUAL_LOAD_BATCHES
/

Drop Table NCI_LABS_MANUAL_LOAD_CTL
/

--DROP VIEWS
Prompt ...Dropping Views
Drop View C3D_ACCESSIBLE_STUDIES_VW
/

Drop View LABTESTS
/

Drop View NCI_CDW_LAB_MAP_CROSSREF
/

Drop View NCI_STUDY_ALL_DCMS_EVENTS_VW
/

Drop View NCI_STUDY_DCMS_VW
/

Drop View NCI_STUDY_DCMS_EVENTS_VW
/

Drop View NCI_STUDY_LABDCM_EVENTS_VW
/

Drop View NCI_UOMS
/

Drop View STUDY_REPEAT_DEFAULTS_VW
/

Drop View DUPLICATE_LAB_MAPPINGS
/

Drop View NCI_LABS_LOAD_SPPDQ_VW
/

Drop View NCI_LAB_LOAD_STUDY_SEC_VW
/

Drop View NCI_LAB_VALID_PATIENTS_VW
/

Drop View PATIENT_ID_PTID_VW
/

Drop View NCI_LAB_DUP_PATIENTS_VW
/

Drop View NCI_LAB_LOAD_STUDY_CTLS_VW
/

Drop View NCI_LABS_DCM_QUESTS_VW
/

--DROP Procedures/Functions/Packages
Prompt ...Dropping Procedures/Functions/Packages
Drop Package AUTOMATE_BDL
/

Drop Package CDW_LOAD_LAB_FTPDATA
/

Drop Package INSERT_LAB_DATA
/

Drop Procedure LOAD_LAB_RESULTS
/

Drop Procedure LOAD_LAB_RESULTS_UPD
/

Drop Package CDW_DATA_TRANSFER_V3
/

Drop Function GET_RESPONSE_VALUE
/

Drop Function MAKE_NUMBER
/

Drop Package NCI_LABS_MANUAL_LOADER
/

PROMPT
PROMPT FINISHED!
PROMPT

Spool off