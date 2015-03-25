/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Dec. 12, 2005                                                 */
/* Description: This is the installation script for the CDW Lab Loader.  */
/*              The CDW Lab Loader is used to load RAW Lab Test Result   */
/*              data files into Oracle tables.  Prepare and process the  */
/*              Lab Test Record for loading into C3D (Oracle Clinical),  */
/*              and load the records into the appropriate study/patient. */
/*                                                                       */
/* EXECUTION NOTE: The following files should be placed into the same    */
/*                 directory. Before this file is execute, the install   */
/*                 directory should be the default directory.            */
/*   FILES:                                                              */
/*          Install_Lab_Loader.sql - This file.                          */
/*          GLRS_SEQ.seq  -- added 11/1/06                               */
/*          MD_LABS_SEQ.seq  -- added 11/1/06                            */
/*          NCI_MANUAL_LOAD_SEQ.seq  -- added 11/1/06                    */
/*          NLB_SEQ.seq                                                  */
/*          NLM_SEQ.seq                                                  */
/*          BDL_TEMP_FILES.sql                                           */
/*          CDW_LAB_RESULTS.sql                                          */
/*          CDW_LAST_LOAD.sql                                            */
/*          CDW_LAST_LOAD_DATA.sql                                       */
/*          GU_LAB_RESULTS_HOLD.sql         -- added 11/1/06             */
/*          GU_LAB_RESULTS_STAGE.sql        -- added 11/1/06             */
/*          MIS_CDR_TESTS.sql                                            */
/*          MIS_LAB_RESULTS_HISTORY.sql                                  */
/*          MDLABS_STG.sql                  -- added 11/1/06             */
/*          MDLABS_HOLD.sql                 -- added 11/1/06             */
/*          NCI_INVALID_LABTESTS.sql                                     */
/*          NCI_INVALID_LABTESTS_DATA.sql                                */
/*          NCI_INVALID_RESULTS.sql                                      */
/*          NCI_INVALID_RESULTS_DATA.sql                                 */
/*          NCI_LABS.sql                                                 */
/*          NCI_LABS_ERROR_LABS.sql                                      */
/*          NCI_LABS_MANUAL_LOAD_STAGE.sql  -- added 11/1/06             */
/*          NCI_LABS_MANUAL_LOAD_HOLD.sql   -- added 11/1/06             */
/*          NCI_LAB_LOAD_CTL.sql                                         */
/*          NCI_LAB_LOAD_CTL_DATA.sql                                    */
/*          NCI_LAB_MAPPING.sql                                          */
/*          NCI_LAB_MAPPING_DATA.sql                                     */
/*          NCI_LAB_VALID_PATIENTS.sql                                   */
/*          NCI_STUDY_LABDCM_EVENTS_TB.sql                               */
/*          NCI_UOM_MAPPING.SQL                                          */
/*          NCI_UOM_MAPPING_DATA.SQL                                     */
/*          NCI_UPLOAD_SYBASE_LAB_RESULTS.sql                            */
/*          NCI_LAB_LOAD_PATIENT_LOAD.sql                                */
/*          BDL_RESPONSE_REPEATS.sql                                     */
/*          C3D_ACCESSIBLE_STUDIES_VW.vw                                 */
/*          LABTESTS.vw                                                  */
/*          NCI_CDW_LAB_MAP_CROSSREF.vw                                  */
/*          NCI_STUDY_ALL_DCMS_EVENTS_VW.vw                              */
/*          NCI_STUDY_DCMS_VW.vw                                         */
/*          NCI_STUDY_DCMS_EVENTS_VW.vw     -- added 11/1/06             */
/*          NCI_STUDY_LABDCM_EVENTS_VW.vw                                */
/*          NCI_UOMS.vw                                                  */
/*          STUDY_REPEAT_DEFAULTS_VW.vw                                  */
/*          DUPLICATE_LAB_MAPPINGS.vw                                    */
/*          NCI_LABS_LOAD_SPPDQ_VW.vw                                    */
/*          NCI_LAB_LOAD_STUDY_SEC_VW.vw     -- added 11/1/06            */
/*          NCI_LABS_REV_SPPDQ_VW.vw                                     */
/*          NCI_LAB_VALID_PATIENTS_VW.vw                                 */
/*          NCI_LAB_VALID_PT_DATES_VW.vw     -- added 11/1/06            */
/*          automate_bdl_pkg.plsql                                       */
/*          CDW_load_lab_FTPData.plsql                                   */
/*          cr_insert_labdata_pkg_vLLI.plsql                             */
/*          load_lab_results.plsql                                       */
/*          load_lab_results_upd.plsql                                   */
/*          cdw_data_transfer_pkg_V3.plsql                               */
/*          SubmitPsubLoad.plsql                                         */
/*          Get_Response.plsql               -- added 11/1/06            */
/*          Make_number.plsql                -- added 11/1/06            */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Modification History:                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- Added condition to exit when error.  Just incase run accidently.
--WHENEVER SQLERROR EXIT

Set Timing off verify off

-- Spool a log file
spool install_Lab_Loader.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  

--install the sequences
Prompt ...Installing Sequences
Prompt * * * * * * *
prompt Sequence GLRS_SEQ
Prompt * * * * * * *
@GLRS_SEQ.seq

Prompt * * * * * * *
prompt Sequence MD_LABS_SEQ
Prompt * * * * * * *
@MD_LABS_SEQ.seq

Prompt * * * * * * *
prompt Sequence NCI_MANUAL_LOAD_SEQ
Prompt * * * * * * *
@NCI_MANUAL_LOAD_SEQ.seq

Prompt * * * * * * *
prompt Sequence NLB_SEQ
Prompt * * * * * * *
@NLB_SEQ.seq

Prompt * * * * * * *
prompt Sequence NLM_SEQ
Prompt * * * * * * *
@NLM_SEQ.seq


--install the table, index and privs
Prompt ...Installing Tables, Index, Synonym and Privileges.
/*          GU_LAB_RESULTS_HOLD.sql         -- added 11/1/06             */
/*          GU_LAB_RESULTS_STAGE.sql        -- added 11/1/06             */
/*          MDLABS_STG.sql                  -- added 11/1/06             */
/*          MDLABS_HOLD.sql                 -- added 11/1/06             */
/*          NCI_LABS_MANUAL_LOAD_STAGE.sql  -- added 11/1/06             */
/*          NCI_LABS_MANUAL_LOAD_HOLD.sql   -- added 11/1/06             */
Prompt * * * * * * *
prompt Object GU_LAB_RESULTS_HOLD
Prompt * * * * * * *
@GU_LAB_RESULTS_HOLD.sql

Prompt * * * * * * *
prompt Object GU_LAB_RESULTS_STAGE
Prompt * * * * * * *
@GU_LAB_RESULTS_STAGE.sql

Prompt * * * * * * *
prompt Object MDLABS_STG
Prompt * * * * * * *
@MDLABS_STG.sql

Prompt * * * * * * *
prompt Object MDLABS_HOLD
Prompt * * * * * * *
@MDLABS_HOLD.sql

Prompt * * * * * * *
prompt Object NCI_LABS_MANUAL_LOAD_STAGE
Prompt * * * * * * *
@NCI_LABS_MANUAL_LOAD_STAGE.sql

Prompt * * * * * * *
prompt Object NCI_LABS_MANUAL_LOAD_HOLD
Prompt * * * * * * *
@NCI_LABS_MANUAL_LOAD_HOLD.sql

Prompt * * * * * * *
prompt Object BDL_TEMP_FILES
Prompt * * * * * * *
@BDL_TEMP_FILES.sql

Prompt * * * * * * * 
Prompt Object CDW_LAB_RESULTS
Prompt * * * * * * *
@CDW_LAB_RESULTS.sql

Prompt * * * * * * *
Prompt Object CDW_LAST_LOAD
Prompt * * * * * * *
@CDW_LAST_LOAD.sql

Prompt * * * * * * *
Prompt Data for CDW_LAST_LOAD
Prompt * * * * * * *
@CDW_LAST_LOAD_DATA.sql

Prompt * * * * * * *
Prompt Object MIS_CDR_TESTS
Prompt * * * * * * *
@MIS_CDR_TESTS.sql

Prompt * * * * * * *
Prompt Object MIS_LAB_RESULTS_HISTORY
Prompt * * * * * * *
@MIS_LAB_RESULTS_HISTORY.sql

Prompt * * * * * * *
Prompt Object NCI_INVALID_LABTESTS
Prompt * * * * * * *
@NCI_INVALID_LABTESTS.sql

Prompt * * * * * * *
Prompt Data for NCI_INVALID_LABTESTS     
Prompt * * * * * * *
@NCI_INVALID_LABTESTS_DATA.sql

Prompt * * * * * * *
Prompt Object NCI_INVALID_RESULTS
Prompt * * * * * * *
@NCI_INVALID_RESULTS.sql

Prompt * * * * * * *
Prompt Data for NCI_INVALID_RESULTS
Prompt * * * * * * *
@NCI_INVALID_RESULTS_DATA.sql

Prompt * * * * * * *
Prompt Object NCI_LABS
Prompt * * * * * * *
@NCI_LABS.sql

Prompt * * * * * * *
Prompt Object NCI_LABS_ERROR_LABS
Prompt * * * * * * *
@NCI_LABS_ERROR_LABS.sql

Prompt * * * * * * *
Prompt Object NCI_LAB_LOAD_CTL
Prompt * * * * * * *
@NCI_LAB_LOAD_CTL.sql

Prompt * * * * * * *
Prompt Data for NCI_LAB_LOAD_CTL
Prompt * * * * * * *
@NCI_LAB_LOAD_CTL_DATA.sql

Prompt * * * * * * *
Prompt Object NCI_LAB_MAPPING
Prompt * * * * * * *
@NCI_LAB_MAPPING.sql

Prompt * * * * * * *
Prompt Data for NCI_LAB_MAPPING
Prompt * * * * * * *
@NCI_LAB_MAPPING_DATA.sql

Prompt * * * * * * *
Prompt Object NCI_LAB_VALID_PATIENTS
Prompt * * * * * * *
@NCI_LAB_VALID_PATIENTS.sql

Prompt * * * * * * *
Prompt Object NCI_STUDY_LABDCM_EVENTS_TB
Prompt * * * * * * *
@NCI_STUDY_LABDCM_EVENTS_TB.sql

Prompt * * * * * * *
Prompt Object NCI_UOM_MAPPING
Prompt * * * * * * *
@NCI_UOM_MAPPING.SQL

Prompt * * * * * * *
Prompt Data for NCI_UOM_MAPPING
Prompt * * * * * * *
@NCI_UOM_MAPPING_DATA.SQL

Prompt * * * * * * *
Prompt Object NCI_UPLOAD_SYBASE_LAB_RESULTS
Prompt * * * * * * *
@NCI_UPLOAD_SYBASE_LAB_RESULTS.sql

Prompt * * * * * * *
Prompt Object NCI_LAB_LOAD_PATIENT_LOAD
Prompt * * * * * * *
@NCI_LAB_LOAD_PATIENT_LOAD.sql

Prompt * * * * * * *
Prompt Object BDL_RESPONSE_REPEATS
Prompt * * * * * * *
@BDL_RESPONSE_REPEATS.sql

Prompt * * * * * * *
Prompt Object NCI_STUDY_PATIENT_IDS
Prompt * * * * * * *
@NCI_STUDY_PATIENT_IDS.sql

Prompt * * * * * * *
Prompt Object NCI_STUDY_PATIENT_IDS_CTL
Prompt * * * * * * *
@NCI_STUDY_PATIENT_IDS_CTL.sql

Prompt * * * * * * *
Prompt Data For NCI_STUDY_PATIENT_IDS_CTL
Prompt * * * * * * *
@NCI_STUDY_PATIENT_IDS_CTL_DATA.sql

Prompt ...Installing Views...
Prompt * * * * * * *
Prompt View C3D_ACCESSIBLE_STUDIES_VW
Prompt * * * * * * *
@C3D_ACCESSIBLE_STUDIES_VW.vw

Prompt * * * * * * *
Prompt View LABTESTS
Prompt * * * * * * *
@LABTESTS.vw

Prompt * * * * * * *
Prompt View NCI_CDW_LAB_MAP_CROSSREF
Prompt * * * * * * *
@NCI_CDW_LAB_MAP_CROSSREF.vw

Prompt * * * * * * *
Prompt View NCI_STUDY_ALL_DCMS_EVENTS_VW
Prompt * * * * * * *
@NCI_STUDY_ALL_DCMS_EVENTS_VW.vw

Prompt * * * * * * *
Prompt View NCI_STUDY_DCMS_VW
Prompt * * * * * * *
@NCI_STUDY_DCMS_VW.vw

Prompt * * * * * * *
Prompt View NCI_STUDY_LABDCM_EVENTS_VW
Prompt * * * * * * *
@NCI_STUDY_LABDCM_EVENTS_VW.vw

Prompt * * * * * * *
Prompt View NCI_UOMS
Prompt * * * * * * *
@NCI_UOMS.vw

Prompt * * * * * * *
Prompt View STUDY_REPEAT_DEFAULTS_VW
Prompt * * * * * * *
@STUDY_REPEAT_DEFAULTS_VW.vw

Prompt * * * * * * *
Prompt View DUPLICATE_LAB_MAPPINGS
Prompt * * * * * * *
@DUPLICATE_LAB_MAPPINGS.vw

Prompt * * * * * * *
Prompt View NCI_LABS_LOAD_SPPDQ_VW
Prompt * * * * * * *
@NCI_LABS_LOAD_SPPDQ_VW.vw

Prompt * * * * * * *
Prompt View NCI_LABS_REV_SPPDQ_VW
Prompt * * * * * * *
@NCI_LABS_REV_SPPDQ_VW.vw

Prompt * * * * * * *
Prompt View NCI_LAB_VALID_PATIENTS_VW
Prompt * * * * * * *
@NCI_LAB_VALID_PATIENTS_VW.vw

Prompt * * * * * * *
Prompt View NCI_STUDY_DCMS_EVENTS_VW
Prompt * * * * * * *
@NCI_STUDY_DCMS_EVENTS_VW.vw

Prompt * * * * * * *
Prompt View NCI_LAB_LOAD_STUDY_SEC_VW
Prompt * * * * * * *
@NCI_LAB_LOAD_STUDY_SEC_VW.vw

Prompt * * * * * * *
Prompt View NCI_LAB_VALID_PT_DATES_VW
Prompt * * * * * * *
@NCI_LAB_VALID_PT_DATES_VW.vw


-- Install Package
Prompt ...Installing Packages
Prompt * * * * * * *
Prompt Package SubmitPsubLoad
Prompt * * * * * * *
@SubmitPsubLoad.plsql

Prompt ...Installing Packages
Prompt * * * * * * *
Prompt Package automate_bdl_pkg
Prompt * * * * * * *
@automate_bdl_pkg.plsql

Prompt * * * * * * *
Prompt Package CDW_load_lab_FTPData
Prompt * * * * * * *
@CDW_load_lab_FTPData.plsql

Prompt * * * * * * *
Prompt Package cr_insert_labdata_pkg_vLLI
Prompt * * * * * * *
@cr_insert_labdata_pkg_vLLI.plsql

Prompt * * * * * * *
Prompt Package load_lab_results
Prompt * * * * * * *
@load_lab_results.plsql

Prompt * * * * * * *
Prompt Package load_lab_results_upd
Prompt * * * * * * *
@load_lab_results_upd.plsql

Prompt * * * * * * *
Prompt Package cdw_data_transfer_pkg_V3
Prompt * * * * * * *
@cdw_data_transfer_pkg_v4_as_V3.plsql

Prompt * * * * * * *
Prompt Function Make_number
Prompt * * * * * * *
@Make_number.plsql

Prompt * * * * * * *
Prompt Function Get_Response
Prompt * * * * * * *
@Get_Response.plsql


PROMPT
PROMPT FINISHED!
PROMPT

Spool off

dir.dat
Lab Loader 1.0.4 to 1.1 with BTRIS Object List.txt
New Text Document.txt
New_Objects
Update_Objects
New_Objects\BTRIS_DATA_TRANSFER.SQL
New_Objects\BTRIS_LAB_INVALID_VALUES.sql
New_Objects\BTRIS_LAB_RESULTS.sql
New_Objects\BTRIS_LAB_TEST_NAMES.sql
New_Objects\BTRIS_LAB_TEST_RESULTS.sql
New_Objects\BTRIS_PROTOCOL_PATIENT.sql
New_Objects\BTRIS_PROTOCOL_STATUS.sql
New_Objects\NCI_LABS_Indexes.SQL
New_Objects\NCI_LAB_LOAD_CTL_Indexes.SQL
New_Objects\NCI_STUDY_ALL_DCM_EVENTS2_VW.SQL
Update_Objects\AUTOMATE_BDL.SQL
Update_Objects\CDW_DATA_TRANSFER_V3.SQL
Update_Objects\INSERT_LAB_DATA.SQL
Update_Objects\LOAD_LAB_RESULTS.SQL
Update_Objects\LOAD_LAB_RESULTS_UPD.SQL
Update_Objects\NCI_CDW_LAB_MAP_CROSSREF.SQL
Update_Objects\NCI_LABS_Alter.sql
Update_Objects\NCI_LABS_DCM_QUESTS_VW.SQL
Update_Objects\NCI_LABS_NCI_LABS_ERR1_Index.sql
Update_Objects\NCI_LABS_NCI_LABS_INX3_Index.sql
Update_Objects\NCI_LAB_LOAD_CTL_Alter.sql
Update_Objects\NCI_LAB_LOAD_STUDY_CTLS_VW.SQL
Update_Objects\NCI_LAB_VALID_PATIENTS.sql
Update_Objects\NCI_STUDY_ALL_DCMS_EVENTS_VW.SQL
