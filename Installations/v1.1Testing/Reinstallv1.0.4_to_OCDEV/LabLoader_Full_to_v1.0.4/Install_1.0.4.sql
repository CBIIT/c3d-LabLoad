-- Simple Install Script for Lab Loader Enhancement SQL Scripts

Spool install_LabLoader_v104

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

-- Table, View and other Objects Here
set verify on echo on feed 1

@alter_tab_nci_lab_load_ctl_qual_val.sql

@alter_tab_nci_labs_qual_val.sql

@NCI_LABS_AUTOLOAD_HOLD.sql

@NCI_LABS_MANUAL_LOAD_BATCHES.sql

@NCI_LABS_MANUAL_LOAD_CTL.sql

@NCI_LABS_MANUAL_LOAD_HOLD.sql

@nci_labs_manual_load_trigger.sql

@NCI_LABS_MANUAL_LOAD_STAGE.sql

@NCI_LABS_DCM_QUESTS_VW.sql

@NCI_LAB_LOAD_STUDY_CTLS_VW.sql

@NCI_STUDY_ALL_DCMS_EVENTS_VW.sql

@NCI_MANUAL_LOAD_BATCH_SEQ.sql

@NCI_MANUAL_LOAD_SEQ.sql

set verify off echo off
-- Packages, Procedures, Functions Here

@cr_insert_labdata_pkg_vLLI.sql

@load_lab_results.sql

@load_lab_results_upd.sql

@nci_labs_manual_loader.plsql

@cdw_data_transfer_pkg_v4_as_V3.sql

set verify on echo on
-- Data Changes Here

Update nci_lab_load_ctl 
   set use_qualify_value = 'N'
  where oc_study = 'ALL';

commit;

Set Verify off Echo off

Spool off
