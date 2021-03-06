--
-- CDW_LAB_RESULTS  (Table) 
--
CREATE TABLE CDW_LAB_RESULTS
(
  RESULT_ID             VARCHAR2(15 BYTE),
  PATIENT_ID            VARCHAR2(10 BYTE),
  RECORD_DATETIME       VARCHAR2(15 BYTE),
  TEST_ID               NUMBER(10),
  TEST_CODE             VARCHAR2(10 BYTE),
  TEST_NAME             VARCHAR2(30 BYTE),
  TEST_UNIT             VARCHAR2(15 BYTE),
  ORDER_ID              VARCHAR2(15 BYTE),
  PARENT_TEST_ID        NUMBER(10),
  ORDER_NUMBER          NUMBER(7,2),
  ACCESSION             CHAR(6 BYTE),
  TEXT_RESULT           VARCHAR2(20 BYTE),
  NUMERIC_RESULT        NUMBER(10,3),
  HI_LOW_FLAG           CHAR(2 BYTE),
  UPDATED_FLAG          NUMBER(5),
  LOW_RANGE             NUMBER(9,4),
  HIGH_RANGE            NUMBER(9,4),
  REPORTED_DATETIME     VARCHAR2(15 BYTE),
  RECEIVED_DATETIME     VARCHAR2(15 BYTE),
  COLLECTED_DATETIME    VARCHAR2(15 BYTE),
  MASKED                CHAR(1 BYTE),
  RANGE                 VARCHAR2(80 BYTE),
  SPECIMEN_ID           NUMBER(10),
  SPECIMEN_MODIFIER_ID  NUMBER(10),
  QUALITATIVE_DICT_ID   NUMBER(10),
  INSERTED_DATETIME     VARCHAR2(15 BYTE),
  UPDATE_DATETIME       VARCHAR2(15 BYTE),
  LOAD_FLAG             VARCHAR2(1 BYTE),
  LOAD_DATE             DATE
)
TABLESPACE &&USERS_TABLESPACE;

--
-- CLR_IDX2  (Index) 
--
CREATE INDEX CLR_IDX2 ON CDW_LAB_RESULTS
(LOAD_FLAG, UPDATED_FLAG)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

--
-- PRC_TEMP_LOAD_FLAG  (Index) 
--
CREATE INDEX PRC_TEMP_LOAD_FLAG ON CDW_LAB_RESULTS
(PATIENT_ID, LOAD_FLAG)
LOGGING
TABLESPACE &&USERS_TABLESPACE;



