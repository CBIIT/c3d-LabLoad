-- This file is used to put the PUBLIC synonyms BACK to their original definitions

Spool reset_original_LabLoad_public_synonyms.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  
-- Views

create public synonym NCI_UOMS for CTDEV.NCI_UOMS;
create public synonym NCI_LABS_LOAD_SPPDQ_VW  for OPS$BDL.NCI_LABS_LOAD_SPPDQ_VW;
create public synonym NCI_LABS_REV_SPPDQ_VW   for OPS$BDL.NCI_LABS_REV_SPPDQ_VW;
create public synonym NCI_STUDY_LABDCM_EVENTS_VW for OPS$BDL.NCI_STUDY_LABDCM_EVENTS_VW;
create public synonym LABTESTS for RXC.LABTESTS;

-- Tables
create public synonym MESSAGE_LOGS   for CTDEV.MESSAGE_LOGS;
create public synonym NCI_UOM_MAIN   for CTDEV.NCI_UOM_MAIN;
create public synonym NCI_LAB_LOAD_CTL  for OPS$BDL.NCI_LAB_LOAD_CTL;
create public synonym NCI_LAB_VALID_PATIENTS  for OPS$BDL.NCI_LAB_VALID_PATIENTS;
create public synonym NCI_LABS for OPS$BDL.NCI_LABS;
create public synonym NCI_LABS_ERROR_LABS  for OPS$BDL.NCI_LABS_ERROR_LABS;
create public synonym NCI_STUDY_LABDCM_EVENTS_TB for OPS$BDL.NCI_STUDY_LABDCM_EVENTS_TB;
create public synonym LOG_UTIL for CTDEV.LOG_UTIL;

spool off

