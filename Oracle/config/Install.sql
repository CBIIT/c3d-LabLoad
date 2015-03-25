-- Simple Install Script for SQL Scripts

Spool install_log
select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

-- Table, View and other Objects Here
set verify on echo on

@Add_Prestudy_blank_col.sql

set verify off echo off
-- Packages, Procedures, Functions Here
@cdw_data_transfer_pkg_v3

set verify on echo on
-- Data Changes Here

Update nci_lab_load_ctl
   set BLANK_PRESTUDY_USE_ENROLL = 'N'
 where oc_study = 'ALL';
 
 Commit;
 
 Set Verify off Echo off

Spool off
