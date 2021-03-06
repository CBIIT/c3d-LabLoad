
SET TIME OFF
SET HEADING ON
SET LINESIZE 150
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
SET NUMWIDTH 6

COLUMN today            NOPRINT NEW_VALUE     datevar

COLUMN 	OC_STUDY 			HEADING "OC STUDY"		FORMAT A12 WRAP
COLUMN 	PATIENT_ID_DCM_NAME		HEADING "PID DCM"		FORMAT A20 WRAP
COLUMN 	PATIENT_ID_QUEST_NAME		HEADING "PID QST"		FORMAT A20 WRAP
COLUMN 	NCI_INST_CD_DCM_NAME		HEADING "INST DCM"		FORMAT A20 WRAP
COLUMN 	NCI_INST_CD_QUEST_NAME		HEADING "INST QST"		FORMAT A20 WRAP
COLUMN 	NCI_INST_CD_CONST		HEADING "INST CONST"		FORMAT A20 WRAP
COLUMN  LABORATORY			HEADING "LAB"			FORMAT A4 WRAP
COLUMN  STOP_LAB_LOAD_FLAG		HEADING "STOP"			FORMAT A4 WRAP
COLUMN  LOAD_OTHER_LABS			HEADING "LD OTH"		FORMAT A6 WRAP
COLUMN  REVIEW_STUDY			HEADING "REV"			FORMAT A4 WRAP
COLUMN  LABTESTNAME_IS_OCLABQUEST	HEADING "TSTNAME"		FORMAT A7 WRAP
COLUMN  DATE_CHECK_CODE			HEADING "DT CHK"		FORMAT A6 WRAP
COLUMN  ENROLLMENT_DATE_DCM		HEADING "ENR DCM"		FORMAT A10 WRAP
COLUMN  ENROLLMENT_DATE_QUEST		HEADING "ENR QST"		FORMAT A8 WRAP
COLUMN  PRESTUDY_LAB_DATE_DCM		HEADING "PREST DCM"		FORMAT A10 WRAP
COLUMN  PRESTUDY_LAB_DATE_QUEST		HEADING "PREST QST"		FORMAT A17 WRAP
COLUMN  PRESTUDY_OFFSET_DAYS		HEADING "PREDYS"		
COLUMN  BLANK_PRESTUDY_USE_ENROLL	HEADING "USE ENRDT"		FORMAT A9 WRAP
COLUMN  OFF_STUDY_DCM			HEADING "OFFST DCM"		FORMAT A14 WRAP
COLUMN  OFF_STUDY_QUEST			HEADING "OFFST QST"		FORMAT A11 WRAP
COLUMN  OFF_STUDY_OFFSET_DAYS		HEADING "OFFDYS"	
SELECT TO_CHAR(SYSDATE,'DD-MON-YY HH:MI:SS AM') today FROM DUAL;

SPOOL LST_LAB_LOAD_CTL_DATA;

DEFINE studytitle =  "LAB_LOADER - CONFIGURATION VALUES - NCI_LAB_LOAD_CTL"
DEFINE filename = "File: LST_LAB_LOAD_CTL_DATA"
DEFINE Progname = "SQl script: LST_LAB_LOAD_CTL_DATA.SQL"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE LEFT filename          CENTER progname   RIGHT 'Page:' FORMAT 09 SQL.PNO 

Select
  OC_STUDY,
  LABORATORY,
  STOP_LAB_LOAD_FLAG,
  LOAD_OTHER_LABS,
  REVIEW_STUDY,
  LABTESTNAME_IS_OCLABQUEST, 
  DATE_CHECK_CODE,
  ENROLLMENT_DATE_DCM,
  ENROLLMENT_DATE_QUEST,
  PRESTUDY_LAB_DATE_DCM,
  PRESTUDY_LAB_DATE_QUEST,
  PRESTUDY_OFFSET_DAYS,
  BLANK_PRESTUDY_USE_ENROLL,
  OFF_STUDY_DCM,
  OFF_STUDY_QUEST,
  OFF_STUDY_OFFSET_DAYS
from NCI_LAB_LOAD_CTL;

SPOOL OFF;

CLEAR COLUMNS

