

set echo off verify off

spool CleanDataCheck

Select 'Checking database for issues before executing validation' "CLEAN DATA CHECK", sysdate "DATE" from dual;

ACCEPT Study_ID prompt "Enter Study ID: " 
ACCEPT Pt_Pos   prompt "Enter Patient Position: " 
ACCEPT Pt_id    prompt "Enter Patient ID: " 

select 'Study Id = '||'&&Study_ID' "Search With" from dual
union
select 'Patient position = '||'&&Pt_Pos' "Search With" from dual
union
select 'Patient Id = '||'&&Pt_id' "Search With" from dual;

select decode(count(*),0,'Patient Position does NOT exist','Patient Position does exist') "Patient Position should exist"
  from patient_positions a, clinical_studies b
 where b.study = '&&Study_ID'
   and a.clinical_study_id = b.clinical_study_id
   and a.patient = '&&Pt_Pos';

select decode(count(*),0,'CDW_LAB_RESULTS is clean','CDW_LAB_RESULTS is NOT clean') "Table should be clean"
  from cdw_lab_results where PATIENT_ID = '&&Pt_id';

select decode(count(*),0,'MIS_LAB_RESULTS_CURRENT is clean','MIS_LAB_RESULTS_CURRENT is NOT clean') "Table should be clean"
  from MIS_LAB_RESULTS_CURRENT where MPI = ltrim('&&Pt_id','0');

select decode(count(*),0,'NCI_LABS is clean','NCI_LABS is NOT clean') "Table should be clean"
  from NCI_LABS where patient_id = '&&Pt_id';

spool off

undefine Pt_id
undefine Study_ID
undefine Pt_Pos

set echo on verify on