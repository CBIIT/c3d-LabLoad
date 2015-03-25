-- This file is used to remove the PUBLIC synonyms of the Lab Loader

Spool Drop_LabLoad_public_synonyms.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  
-- Views

drop public synonym NCI_UOMS;
drop public synonym NCI_LABS_LOAD_SPPDQ_VW;
drop public synonym NCI_LABS_REV_SPPDQ_VW;
drop public synonym NCI_STUDY_LABDCM_EVENTS_VW;
drop public synonym LABTESTS;

-- Tables
drop public synonym NCI_UOM_MAIN;
drop public synonym NCI_LAB_LOAD_CTL;
drop public synonym NCI_LAB_VALID_PATIENTS;
drop public synonym NCI_LABS;
drop public synonym NCI_LABS_ERROR_LABS;
drop public synonym NCI_STUDY_LABDCM_EVENTS_TB;
drop public synonym MESSAGE_LOGS;

-- Procedures
drop public synonym LOG_UTIL;

spool off

