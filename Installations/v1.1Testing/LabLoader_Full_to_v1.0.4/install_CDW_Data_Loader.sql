/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Apr. 04, 2006                                                 */
/* Description: This is the installation script for the CDW Data Loader. */
/*              The CDW Data Loader is used to load RAW Lab Test Result  */
/*              data files into Oracle tables.  These tables are used    */
/*              by various Discoverer Reports for Lab Load verification  */
/*                                                                       */
/* EXECUTION NOTE: The following files should be placed into the same    */
/*                 directory. Before this file is execute, the install   */
/*                 directory should be the default directory.            */
/*   FILES:                                                              */
/*          Install_CDW_Data_Loader.sql - This file.                     */
/*          MIS_CDR_TESTS.sql - Lab Test ID Table                        */
/*          MIS_LAB_RESULTS_CURRENT.sql - Current Lab Test Results       */
/*          MIS_LAB_RESULTS_HISTORY.sql - Historical Lab Test Results    */
/*          MIS_PATIENT_LIST.sql - Patient Id Table                      */
/*          MIS_PROT_PAT_CDRLIST.sql - Protocol/Patient Relationships    */
/*          MIS_PROTOCOL_LIST.sql - Protocol Table                       */
/*          CDW_load_sybase_FTPData.sql - Procedure for loading          */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Modification History:                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- Added condition to exit when error.  Just incase run accidently.
--WHENEVER SQLERROR EXIT

Set Timing off verify off

-- Spool a log file
spool install_CDW_Data_Loader.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

--install the table, index and privs
Prompt ...Installing All Tables, Indexes, Synonyms and Privileges.
Prompt * * * * * * *
prompt Object MIS_CDR_TESTS
Prompt * * * * * * *
@MIS_CDR_TESTS.sql

Prompt * * * * * * * 
Prompt Object MIS_LAB_RESULTS_CURRENT
Prompt * * * * * * *
@MIS_LAB_RESULTS_CURRENT.sql

Prompt * * * * * * *
Prompt Object MIS_LAB_RESULTS_HISTORY
Prompt * * * * * * *
@MIS_LAB_RESULTS_HISTORY.sql

Prompt * * * * * * *
Prompt Data for MIS_PATIENT_LIST
Prompt * * * * * * *
@MIS_PATIENT_LIST.sql

Prompt * * * * * * *
Prompt Object MIS_PROT_PAT_CDRLIST
Prompt * * * * * * *
@MIS_PROT_PAT_CDRLIST.sql

Prompt * * * * * * *
Prompt Object MIS_PROTOCOL_LIST
Prompt * * * * * * *
@MIS_PROTOCOL_LIST.sql


-- Install Package
Prompt ...Installing Packages
Prompt * * * * * * *
Prompt Package CDW_load_sybase_FTPData
Prompt * * * * * * *
@CDW_load_sybase_FTPData.sql

PROMPT
PROMPT FINISHED!
PROMPT

Spool off
