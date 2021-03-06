
--
-- NCI_LABS_MANUAL_LOAD_HOLD  (Table) 
--
CREATE TABLE NCI_LABS_MANUAL_LOAD_HOLD
(
  STUDY                VARCHAR2(15 BYTE),
  PATIENT_ID           VARCHAR2(10 BYTE),
  OC_PATIENT_POS       VARCHAR2(12 BYTE),
  LAB_SAMPLE_DATE_RAW  VARCHAR2(20 BYTE),
  LAB_SAMPLE_TIME_RAW  VARCHAR2(20 BYTE),
  LAB_TEST_NAME        VARCHAR2(200 BYTE),
  LAB_TEST_RESULT      VARCHAR2(300 BYTE),
  LAB_TEST_UOM         VARCHAR2(20 BYTE),
  LAB_TEST_RANGE       VARCHAR2(80 BYTE),
  LABORATORY           VARCHAR2(10 BYTE),
  RECEIVED_DATE        DATE,
  RECORD_ID            NUMBER(10)
)
TABLESPACE  &&USERS_TABLESPACE;
