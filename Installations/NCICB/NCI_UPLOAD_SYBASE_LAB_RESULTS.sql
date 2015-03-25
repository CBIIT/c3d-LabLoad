--
-- NCI_UPLOAD_SYBASE_LAB_RESULTS  (Table) 
--
CREATE TABLE NCI_UPLOAD_SYBASE_LAB_RESULTS
(
  RESULT_ID             VARCHAR2(20 BYTE),
  PATIENT_ID            VARCHAR2(15 BYTE),
  RECORD_DATETIME       VARCHAR2(30 BYTE),
  TEST_ID               NUMBER(10),
  TEST_CODE             VARCHAR2(10 BYTE),
  TEST_NAME             VARCHAR2(30 BYTE),
  TEST_UNIT             VARCHAR2(15 BYTE),
  ORDER_ID              VARCHAR2(20 BYTE),
  PARENT_TEST_ID        NUMBER(10),
  ORDER_NUMBER          NUMBER(7,2),
  ACCESSION             CHAR(6 BYTE),
  TEXT_RESULT           VARCHAR2(20 BYTE),
  NUMERIC_RESULT        NUMBER(10,3),
  HI_LOW_FLAG           CHAR(2 BYTE),
  UPDATED_FLAG          NUMBER(5)               NOT NULL,
  LOW_RANGE             NUMBER(9,4),
  HIGH_RANGE            NUMBER(9,4),
  REPORTED_DATETIME     VARCHAR2(30 BYTE),
  RECEIVED_DATETIME     VARCHAR2(30 BYTE),
  COLLECTED_DATETIME    VARCHAR2(30 BYTE),
  MASKED                CHAR(1 BYTE),
  RANGE                 VARCHAR2(80 BYTE),
  SPECIMEN_ID           NUMBER(10),
  SPECIMEN_MODIFIER_ID  NUMBER(10),
  QUALITATIVE_DICT_ID   NUMBER(10),
  INSERTED_DATETIME     VARCHAR2(30 BYTE),
  UPDATE_DATETIME       VARCHAR2(30 BYTE),
  UPLOAD_DATE           DATE
)
TABLESPACE &&USERS_TABLESPACE;

