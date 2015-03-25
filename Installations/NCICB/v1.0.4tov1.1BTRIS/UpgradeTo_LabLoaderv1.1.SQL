/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Feb 2, 2012                                                   */
/* Description: This is the upgrade script for the C3D Lab Loader from   */
/*              v1.0.4 to v1.1. The C3DW Lab Loader is used to load RAW  */
/*    Lab Test Result data into Oracle tables; prepare and process the   */
/*    Lab Test Record for loading into C3D (Oracle Clinical), and load   */
/*    the records into the appropriate study/patient.                    */
/*    Version 1.1 includes a major change in processing to support data  */
/*    from different source Laboratories, primarily BTRIS.               */
/*                                                                       */
/* EXECUTION NOTE: There are two subdirectories as part of this package  */
/*                 and are named to reflect the types of objects scripts */
/*                 they hold.                                            */
/*   FILES:                                                              */
/*       New Objects                                                     */
/*          New_Objects\BTRIS_DATA_TRANSFER.SQL                          */
/*          New_Objects\BTRIS_LAB_INVALID_VALUES.sql                     */
/*          New_Objects\BTRIS_LAB_RESULTS.sql                            */
/*          New_Objects\BTRIS_LAB_TEST_NAMES.sql                         */
/*          New_Objects\BTRIS_LAB_TEST_RESULTS.sql                       */
/*          New_Objects\BTRIS_PROTOCOL_PATIENT.sql                       */
/*          New_Objects\BTRIS_PROTOCOL_STATUS.sql                        */
/*          New_Objects\NCI_LABS_Indexes.SQL                             */
/*          New_Objects\NCI_LAB_LOAD_CTL_Indexes.SQL                     */
/*          New_Objects\NCI_STUDY_ALL_DCM_EVENTS2_VW.SQL                 */
/*                                                                       */
/*       Altered Objects                                                 */
/*          Update_Objects\AUTOMATE_BDL.SQL                              */
/*          Update_Objects\CDW_DATA_TRANSFER_V3.SQL                      */
/*          Update_Objects\INSERT_LAB_DATA.SQL                           */
/*          Update_Objects\LOAD_LAB_RESULTS.SQL                          */
/*          Update_Objects\LOAD_LAB_RESULTS_UPD.SQL                      */
/*          Update_Objects\NCI_CDW_LAB_MAP_CROSSREF.SQL                  */
/*          Update_Objects\NCI_LABS_Alter.sql                            */
/*          Update_Objects\NCI_LABS_DCM_QUESTS_VW.SQL                    */
/*          Update_Objects\NCI_LABS_NCI_LABS_ERR1_Index.sql              */
/*          Update_Objects\NCI_LABS_NCI_LABS_INX3_Index.sql              */
/*          Update_Objects\NCI_LAB_LOAD_CTL_Alter.sql                    */
/*          Update_Objects\NCI_LAB_LOAD_STUDY_CTLS_VW.SQL                */
/*          Update_Objects\NCI_LAB_VALID_PATIENTS.sql                    */
/*          Update_Objects\NCI_STUDY_ALL_DCMS_EVENTS_VW.SQL              */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Modification History:                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- Added condition to exit when error.
--WHENEVER SQLERROR EXIT

Set Timing off verify off

-- Spool a log file
spool UpgradeTo_LabLoaderv1.1.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", 
       User "User",
       'Lab Loader v1.0.4 to v1.1 Install', "Installer"
  from dual;

--install new objects
Prompt Installing New Objects

--install the sequences
Prompt ...Installing Sequences
Prompt * * * * * * *
prompt No New Sequences

--install the table, index and privs
Prompt ...Installing Tables, Index, Synonym and Privileges.
Prompt * * * * * * *
prompt Table BTRIS_DATA_TRANSFER
Prompt * * * * * * *
@New_Objects\BTRIS_DATA_TRANSFER.SQL

Prompt * * * * * * *
prompt Table BTRIS_LAB_INVALID_VALUES
Prompt * * * * * * *
@New_Objects\BTRIS_LAB_INVALID_VALUES.sql

Prompt * * * * * * *
prompt Table BTRIS_LAB_RESULTS
Prompt * * * * * * *
@New_Objects\BTRIS_LAB_RESULTS.sql

Prompt * * * * * * *
prompt Table BTRIS_LAB_TEST_NAMES
Prompt * * * * * * *
@New_Objects\BTRIS_LAB_TEST_NAMES.sql

Prompt * * * * * * *
prompt Table BTRIS_LAB_TEST_RESULTS
Prompt * * * * * * *
@New_Objects\BTRIS_LAB_TEST_RESULTS.sql

Prompt * * * * * * *
prompt Table BTRIS_PROTOCOL_PATIENT
Prompt * * * * * * *
@New_Objects\BTRIS_PROTOCOL_PATIENT.sql

Prompt * * * * * * *
prompt Table BTRIS_PROTOCOL_STATUS.sql
Prompt * * * * * * *
@New_Objects\BTRIS_PROTOCOL_STATUS.sql

Prompt * * * * * * * 
Prompt Indexes for NCI_LABS
Prompt * * * * * * *
@New_Objects\NCI_LABS_Indexes.SQL

Prompt * * * * * * *
Prompt Indexes for NCI_LAB_LOAD_CTL
Prompt * * * * * * *
@New_Objects\NCI_LAB_LOAD_CTL_Indexes.SQL

Prompt ...Installing New Views...
Prompt * * * * * * *
Prompt View NCI_STUDY_ALL_DCM_EVENTS2_VW
Prompt * * * * * * *
@New_Objects\NCI_STUDY_ALL_DCM_EVENTS2_VW.SQL

--install ALTERED objects
Prompt Installing Altered Objects

Prompt ...Altering Tables...
Prompt * * * * * * *
Prompt Table NCI_LABS
Prompt * * * * * * *
@Update_Objects\NCI_LABS_Alter.sql

Prompt * * * * * * *
Prompt Table NCI_LAB_LOAD_CTL
Prompt * * * * * * *
@Update_Objects\NCI_LAB_LOAD_CTL_Alter.sql

Prompt * * * * * * *
Prompt Table NCI_LAB_VALID_PATIENTS
Prompt * * * * * * *
@Update_Objects\NCI_LAB_VALID_PATIENTS.sql

Prompt ...Altering Indexes...
Prompt * * * * * * *
Prompt Index NCI_LABS_ERR1 on Table NCI_LABS
Prompt * * * * * * *
@Update_Objects\NCI_LABS_NCI_LABS_ERR1_Index.sql

Prompt * * * * * * *
Prompt Index NCI_LABS_INX3 on Table NCI_LABS
Prompt * * * * * * *
@Update_Objects\NCI_LABS_NCI_LABS_INX3_Index.sql

Prompt ...Altering Views...
Prompt * * * * * * *
Prompt View NCI_CDW_LAB_MAP_CROSSREF
Prompt * * * * * * *
@Update_Objects\NCI_CDW_LAB_MAP_CROSSREF.SQL

Prompt * * * * * * *
Prompt View NCI_LABS_DCM_QUESTS_VW
Prompt * * * * * * *
@Update_Objects\NCI_LABS_DCM_QUESTS_VW.SQL

Prompt * * * * * * *
Prompt View NCI_LAB_LOAD_STUDY_CTLS_VW
Prompt * * * * * * *
@Update_Objects\NCI_LAB_LOAD_STUDY_CTLS_VW.SQL

Prompt * * * * * * *
Prompt View NCI_STUDY_ALL_DCMS_EVENTS_VW
Prompt * * * * * * *
@Update_Objects\NCI_STUDY_ALL_DCMS_EVENTS_VW.SQL

-- Install Function/Procedure/Package
Prompt ...Altering Procedures
Prompt * * * * * * *
Prompt Procedure AUTOMATE_BDL
Prompt * * * * * * *
@Update_Objects\AUTOMATE_BDL.SQL

Prompt * * * * * * *
Prompt Procedure LOAD_LAB_RESULTS
Prompt * * * * * * *
@Update_Objects\LOAD_LAB_RESULTS.SQL

Prompt * * * * * * *
Prompt Procedure LOAD_LAB_RESULTS_UPD
Prompt * * * * * * *
@Update_Objects\LOAD_LAB_RESULTS_UPD.SQL

Prompt ...Altering Packages
Prompt * * * * * * *
Prompt Package INSERT_LAB_DATA
Prompt * * * * * * *
@Update_Objects\INSERT_LAB_DATA.SQL

Prompt * * * * * * *
Prompt Package CDW_DATA_TRANSFER_V3
Prompt * * * * * * *
@Update_Objects\CDW_DATA_TRANSFER_V3.SQL

PROMPT
PROMPT FINISHED!
PROMPT

Spool off

