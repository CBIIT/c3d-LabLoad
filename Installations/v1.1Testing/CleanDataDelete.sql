

set echo off verify off timing off

spool CleanDataDelete

Select 'Deleting from database before executing validation' "CLEAN DATA DELETE", sysdate "DATE" from dual;

ACCEPT Study_ID prompt "Enter Study ID: " 
ACCEPT Pt_Pos   prompt "Enter Patient Position: " 
ACCEPT Pt_id    prompt "Enter Patient ID: " 

select 'Study Id = '||'&&Study_ID' "Search With" from dual
union
select 'Patient position = '||'&&Pt_Pos' "Search With" from dual
union
select 'Patient Id = '||'&&Pt_id' "Search With" from dual;


Select 'Use OPA Conduct -> Security -> Delete Study Information to remove the following documents from the patient' "NOTE"
from Dual;

select distinct rpad(d.name,30,' ') || ' - "' ||document_number ||'"' "DOCUMENTS NEEDING DELETED"
  from dcis d, received_dcis rd, clinical_studies a
 where a.study = '&&Study_ID'
   and a.clinical_study_id = rd.clinical_study_id
   and rd.patient = '&&Pt_Pos'
   and d.dci_id = rd.dci_id;

select 'Deleting records from CDW_LAB_RESULTS' "NOTE" from dual;

delete from cdw_lab_results where PATIENT_ID = '&&Pt_id';

select 'Deleting records from MIS_LAB_RESULTS_CURRENT' "NOTE" from dual;

delete from MIS_LAB_RESULTS_CURRENT where MPI = ltrim('&&Pt_id','0');

select 'Deleting records from NCI_LABS' "NOTE" from dual;

delete from NCI_LABS where patient_id = '&&Pt_id';

Select 'Enter "COMMIT;" to complete the deletion or "ROLLBACK;" to cancel the deletion' "NOTE"
from Dual;

spool off

undefine Pt_id
undefine Study_ID
undefine Pt_Pos

set echo on verify on