
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
COLUMN 	DCI_BOOK_STATUS_CODE		HEADING "DCIBOOK - STATUS CODE"		FORMAT A22

SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL ACTIVE_DCIBOOK;

DEFINE studytitle =  "LAB_LOADER - ERROR IF NOT AT LEAST 1 ACTIVE_DCIBOOK"
DEFINE filename = "File: ACTIVE_DCIBOOK"
DEFINE Progname = "SQl script: ACTIVE_DCIBOOK.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select distinct
    a.OC_STUDY,
    a.OC_LAB_PANEL,
    a.OC_LAB_SUBSET,
    c.DCM_SUBSET_SN,
    e.NAME DCI_NAME,
    g.NAME DCI_BOOK_NAME,
    g.DCI_BOOK_STATUS_CODE
from
NCI_LABS a,
CLINICAL_STUDIES b,
DCMS c,
DCI_MODULES d,
DCIS e,
DCI_BOOK_PAGES f,
DCI_BOOKS g
WHERE 
a.LOAD_FLAG = 'L' and
a.OC_STUDY = b.STUDY and 
a.oc_lab_panel = c.name and
a.oc_lab_subset = c.subset_name and
b.clinical_study_id = c.clinical_study_id and
c.dcm_id = d.dcm_id and
c.dcm_subset_sn = d.dcm_subset_sn and
d.dci_id = e.dci_id and
e.dci_id = f.dci_id and
f.dci_book_id = g.dci_book_id and
g.dci_book_status_code = 'A'
order by 1,2;

SPOOL OFF;

CLEAR COLUMNS
