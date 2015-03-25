
SET TIME OFF
SET HEADING ON
SET LINESIZE 120
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

COLUMN 	STUDY 				HEADING "OC STUDY"		FORMAT A20
COLUMN 	PT				HEADING "OC PATIENT POSITION"	FORMAT A20
COLUMN 	PT_ID				HEADING "PATIENT ID (LAB)"	FORMAT A20
COLUMN 	NCI_INST_CD			HEADING "NCI INSTITUTION"	FORMAT A20
COLUMN 	LABORATORY			HEADING "LABORATORY"		FORMAT A20


SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL NCI_LAB_VALID_PATIENTS_DATA;

DEFINE studytitle =  "LAB_LOADER - NCI_LAB_VALID_PATIENTS"
DEFINE filename = "File: NCI_LAB_VALID_PATIENTS_DATA"
DEFINE Progname = "SQl script: NCI_LAB_VALID_PATIENTS_DATA.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select
  STUDY,
  PT_ID,
  PT, 
  NCI_INST_CD,
  LABORATORY
from NCI_LAB_VALID_PATIENTS
ORDER BY 1, 2, 3;

SPOOL OFF;

CLEAR COLUMNS


