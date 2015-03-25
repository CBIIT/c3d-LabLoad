-- Simple Install Script for Lab Loader Enhancement SQL Scripts

Spool install_LabLoader_v103

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

-- Table, View and other Objects Here
set verify on echo on

@nci_lab_mapping_alts.sql

@nci_lab_load_ctl_alts.sql

@nci_lab_valid_patients_vw.vw

@nci_lab_dup_patients_vw.vw

@nci_lab_load_study_ctls_vw.vw

@nci_cdw_lab_map_crossref.vw


set verify off echo off
-- Packages, Procedures, Functions Here

@load_lab_results_upd.sql

@load_lab_results.sql

@cdw_data_transfer_pkg_v4_as_V3.sql

set verify on echo on
-- Data Changes Here

Update nci_lab_load_ctl 
   set allow_mult_patients = 'N', map_version = '1.0'
  where oc_study = 'ALL';

update nci_lab_mapping
   set map_version = '1.0';

commit;

Set Verify off Echo off

Spool off
