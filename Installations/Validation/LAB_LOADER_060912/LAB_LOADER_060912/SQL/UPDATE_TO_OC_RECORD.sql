
SET TIME OFF
SET HEADING ON
SET LINESIZE 200
SET PAGESIZE 52
SET TRIMOUT OFF
SET TRIMSPOOL OFF
SET PAUSE OFF
SET WRAP OFF
SET ECHO OFF
SET DOCUMENT OFF
SET VERIFY OFF
SET SHOW OFF
SET FEEDBACK OFF
SET ARRAYSIZE 15
SET NUMWIDTH 10

COLUMN today            NOPRINT NEW_VALUE     datevar

COLUMN 	UNIT			HEADING "NCI_LABS UNIT"		FORMAT A20
COLUMN 	VALUE_TEXT		HEADING "VALUE"			FORMAT A20
COLUMN 	default_value_text	HEADING "DEFAULT VALUE"		FORMAT A20		

SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL UPDATE_TO_OC_RECORD;

DEFINE studytitle =  "LAB_LOADER - OC RECORDS"
DEFINE filename = "File: UPDATE_TO_OC_RECORD"
DEFINE Progname = "SQl script: UPDATE_TO_OC_RECORD.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select distinct e.study, a.patient, a.dcm_date, a.dcm_time, b.name, b.subset_name, 
c.question_name, f.name, f.display_sn, 
d.value_text
from 
RECEIVED_DCMS a,
DCMS b,
DCM_QUESTIONS c,
RESPONSES d,
clinical_studies e,
dcm_question_groups f
-- dcm_ques_repeat_defaults f
where a.clinical_study_id = b.clinical_study_id and
a.dcm_id = b.dcm_id and
a.dcm_subset_sn = b.dcm_subset_sn and
a.dcm_layout_sn = b.dcm_layout_sn and
b.dcm_id = c.dcm_id and
b.dcm_subset_sn = c.dcm_que_dcm_subset_sn and
b.dcm_layout_sn = c.dcm_que_dcm_layout_sn and
c.dcm_question_id = d.dcm_question_id and
a.clinical_study_id = d.clinical_study_id and
a.received_dcm_id = d.received_dcm_id and
a.clinical_study_id = e.clinical_study_id and
a.clinical_study_id = f.clinical_study_id and
b.dcm_id = f.dcm_id and
e.study = 'LAB_LOADER' and a.patient = '102'
order by 1,2,3,4,5,6,7,8;

SPOOL OFF;


CLEAR COLUMNS

