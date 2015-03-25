-- Simple Install Script for CDW Data Load Public Synonyms

set echo on verify on feedback on 

Spool CDW_DataLoad_Public_Syns

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

Drop public synonym MIS_LAB_RESULTS_HISTORY;

Drop public synonym MIS_CDR_TESTS;

Drop public synonym MIS_LAB_RESULTS_CURRENT;

Drop public synonym MIS_PATIENT_LIST;

Drop public synonym MIS_PROTOCOL_LIST;

Drop public synonym MIS_PROT_PAT_CDRLIST;


Create public synonym MIS_LAB_RESULTS_HISTORY for &&CDW_DataLoad_Owner..MIS_LAB_RESULTS_HISTORY;

Create public synonym MIS_CDR_TESTS for &&CDW_DataLoad_Owner..MIS_CDR_TESTS;

Create public synonym MIS_LAB_RESULTS_CURRENT for &&CDW_DataLoad_Owner..MIS_LAB_RESULTS_CURRENT;

Create public synonym MIS_PATIENT_LIST for &&CDW_DataLoad_Owner..MIS_PATIENT_LIST;

Create public synonym MIS_PROTOCOL_LIST for &&CDW_DataLoad_Owner..MIS_PROTOCOL_LIST;

Create public synonym MIS_PROT_PAT_CDRLIST for &&CDW_DataLoad_Owner..MIS_PROT_PAT_CDRLIST;

Spool off

undefine CDW_DataLoad_owner

Set Verify off Echo off
