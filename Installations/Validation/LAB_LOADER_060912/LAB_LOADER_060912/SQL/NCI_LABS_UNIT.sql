
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


COLUMN 	UNIT				HEADING "UNIT"			FORMAT A20
COLUMN 	LABORATORY			HEADING "LABORATORY"		FORMAT A20


SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL NCI_LABS_UNIT;

DEFINE studytitle =  "LAB_LOADER - NCI_LABS - LAB and MAPPED UNIT OF MEASURE"
DEFINE filename = "File: NCI_LABS_UNIT"
DEFINE Progname = "SQl script: NCI_LABS_UNIT.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select distinct b.laboratory, b.unit
from CDW_LAB_RESULTS a, NCI_LABS b, NCI_UOM_MAPPING c
where a.result_id = b.cdw_result_id and
b.laboratory = c.laboratory and
a.test_unit = c.source;

SPOOL OFF;

CLEAR COLUMNS
