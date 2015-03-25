Spool create_public_synonyms.lst
-- Views

create public synonym NCI_UOMS  for &&LabLoadOwner..NCI_UOMS;
create public synonym NCI_LABS_LOAD_SPPDQ_VW   for &&LabLoadOwner..NCI_LABS_LOAD_SPPDQ_VW;
create public synonym NCI_LABS_REV_SPPDQ_VW    for &&LabLoadOwner..NCI_LABS_REV_SPPDQ_VW;
create public synonym NCI_STUDY_LABDCM_EVENTS_VW  for &&LabLoadOwner..NCI_STUDY_LABDCM_EVENTS_VW;
create public synonym LABTESTS  for &&LabLoadOwner..LABTESTS;

-- Tables
create public synonym NCI_LAB_LOAD_CTL   for &&LabLoadOwner..NCI_LAB_LOAD_CTL;
create public synonym NCI_LAB_VALID_PATIENTS   for &&LabLoadOwner..NCI_LAB_VALID_PATIENTS;
create public synonym NCI_LABS  for &&LabLoadOwner..NCI_LABS;
create public synonym NCI_LABS_ERROR_LABS   for &&LabLoadOwner..NCI_LABS_ERROR_LABS;
create public synonym NCI_STUDY_LABDCM_EVENTS_TB  for &&LabLoadOwner..NCI_STUDY_LABDCM_EVENTS_TB;
create public synonym MESSAGE_LOGS for &&Log_Util_Owner..MESSAGE_LOGS;
Create public synonym NCI_UOM_MAIN for &&UOM_Table_Owner..NCI_UOM_MAIN;


-- Procedures
create public synonym LOG_UTIL for &&Log_Util_Owner..LOG_UTIL;

undefine Log_Util_Owner
undefine LabLoadOwner
undefine UOM_Table_Owner

spool off

