
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
SET NUMWIDTH 12

COLUMN today            NOPRINT NEW_VALUE     datevar


COLUMN 	PATIENT_ID			HEADING "PATIENT ID"		FORMAT A10
COLUMN 	RECORD_ID			HEADING "RECORD ID"	
COLUMN 	CDW_RESULT_ID			HEADING "RESULT ID"		
COLUMN 	SAMPLE_DATETIME			HEADING "SAMPLE DATETIME"	FORMAT A15
COLUMN 	RECEIVED_DATE			HEADING "RECEIVED DATE"		FORMAT A15
COLUMN 	DATE_CREATED			HEADING "DATE CREATED"		FORMAT A15
COLUMN 	DATE_MODIFIED			HEADING "DATE MODIFIED"		FORMAT A15
COLUMN 	LOAD_MARK_DATE			HEADING "LOAD MARK DATE"	FORMAT A15
COLUMN 	LOAD_MARK_USER			HEADING "LOAD MARK USER"	FORMAT A15
COLUMN 	LOAD_FLAG			HEADING "LOAD FLAG"		FORMAT A10
COLUMN 	ERROR_REASON			HEADING "ERROR	"		FORMAT A50 WRAP
COLUMN 	RESNUM				HEADING "# RECORDS"		

SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

ACCEPT PTID PROMPT "Enter Patient ID: "

SPOOL NCI_LABS_LOADN_&PTID;

DEFINE studytitle =  "LAB_LOADER - NCI_LABS - LOAD FLAG=N - Patient &&PTID"
DEFINE filename = "File: NCI_LABSS_LOADN_PTID"
DEFINE Progname = "SQl script: NCI_LABS_LOADN_PTID.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select
  RECORD_ID,
  CDW_RESULT_ID,
  SAMPLE_DATETIME,
  RECEIVED_DATE,
  DATE_CREATED,
  LOAD_FLAG,
  ERROR_REASON
from NCI_LABS
where LOAD_FLAG = 'N' AND PATIENT_ID = '&PTID'
order by
  CDW_RESULT_ID,
  RECORD_ID;

SPOOL OFF;

CLEAR COLUMNS

