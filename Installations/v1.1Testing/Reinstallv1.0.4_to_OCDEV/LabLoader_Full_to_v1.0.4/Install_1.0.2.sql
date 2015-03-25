-- Simple Install Script for Lab Loader Enhancement SQL Scripts

Spool install_LabLoader_v102

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

-- Table, View and other Objects Here
set verify on echo on

@nci_lab_valid_patients_vw.vw

set verify off echo off
-- Packages, Procedures, Functions Here
@load_lab_results.plsql

@load_lab_results_upd.plsql

@cdw_data_transfer_pkg_v4_as_V3.plsql

set verify on echo on
-- Data Changes Here

-- none

Set Verify off Echo off

Spool off
