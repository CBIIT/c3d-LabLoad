
SET TIME OFF
SET HEADING ON
SET LINESIZE 140
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


COLUMN 	OC_STUDY			HEADING "NCI_LABS - STUDY"		FORMAT A20
COLUMN 	OC_LAB_PANEL			HEADING "NCI_LABS - LAB_PANEL"		FORMAT A20
COLUMN 	OC_LAB_SUBSET			HEADING "NCI_LABS - LAB SUBSET"		FORMAT A30
COLUMN 	DCM_SUBSET_SN			HEADING "DCMS - SS#"			
COLUMN 	DCI_NAME			HEADING "DCIS - NAME"			FORMAT A15
COLUMN 	DCI_BOOK_NAME			HEADING "DCIBOOKS - NAME"		FORMAT A15
COLUMN 	COLLECT_TIME_FLAG		HEADING "COLLECT TIME"			FORMAT A15

SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL DCI_TIME_REQUIRED;

DEFINE studytitle =  "LAB_LOADER - DCI_TIME_REQUIRED"
DEFINE filename = "File: DCI_TIME_REQUIRED"
DEFINE Progname = "SQl script: DCI_TIME_REQUIRED.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select distinct
    a.OC_STUDY,
    a.OC_LAB_PANEL,
    a.OC_LAB_SUBSET,
    c.DCM_SUBSET_SN,
    e.NAME DCI_NAME,
    e.collect_time_flag
from
NCI_LABS a,
CLINICAL_STUDIES b,
DCMS c,
DCI_MODULES d,
DCIS e
WHERE 
a.LOAD_FLAG = 'L' and
a.OC_STUDY = b.STUDY and 
a.oc_lab_panel = c.name and
a.oc_lab_subset = c.subset_name and
b.clinical_study_id = c.clinical_study_id and
c.dcm_id = d.dcm_id and
c.dcm_subset_sn = d.dcm_subset_sn and
d.dci_id = e.dci_id and
e.dci_status_code = 'A'
order by 1,2;

SPOOL OFF;

CLEAR COLUMNS

