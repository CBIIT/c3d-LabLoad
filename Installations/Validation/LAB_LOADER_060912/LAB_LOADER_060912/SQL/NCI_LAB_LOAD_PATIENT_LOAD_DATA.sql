
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

COLUMN 	PT_ID				HEADING "PATIENT ID"	FORMAT A20
COLUMN 	LOAD_FLAG			HEADING "LOAD FLAG"	FORMAT A20
COLUMN 	LOAD_DATE			HEADING "LOAD DATE"	FORMAT A20


SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL NCI_LAB_LOAD_PATIENT_LOAD_DATA;

DEFINE studytitle =  "LAB_LOADER - NCI_LAB_LOAD_PATIENT_LOAD"
DEFINE filename = "File: NCI_LAB_LOAD_PATIENT_LOAD_DATA"
DEFINE Progname = "SQl script: NCI_LAB_LOAD_PATIENT_LOAD_DATA.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select
  PT_ID,
  LOAD_FLAG,
  LOAD_DATE
from NCI_LAB_LOAD_PATIENT_LOAD
ORDER BY 1, 2;

SPOOL OFF;

CLEAR COLUMNS


