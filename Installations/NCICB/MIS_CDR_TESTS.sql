CREATE TABLE MIS_CDR_TESTS
(
  TEST_ID           NUMBER(18),
  EC_ID             VARCHAR2(10 BYTE),
  TEST_CODE         VARCHAR2(10 BYTE),
  TEST_UNIT         VARCHAR2(15 BYTE),
  TEST_NAME         VARCHAR2(30 BYTE),
  TEST_TYPE         VARCHAR2(1 BYTE),
  ABBREVIATED_NAME  VARCHAR2(15 BYTE),
  TEST_TIME         VARCHAR2(20 BYTE),
  ADDED_DATE        VARCHAR2(30 BYTE),
  EFFECTIVE_DATE    VARCHAR2(30 BYTE),
  MODIFIED_DATE     VARCHAR2(30 BYTE),
  FIRST_RESULT_ID   NUMBER(18),
  LAST_RESULT_ID    NUMBER(18)
)
TABLESPACE &&USERS_TABLESPACE;

CREATE INDEX MIS_CDR_TESTS_INDX2 ON MIS_CDR_TESTS
(TEST_CODE, TEST_ID)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

CREATE INDEX MIS_CDR_TEST_IDX3 ON MIS_CDR_TESTS
(EC_ID, TEST_CODE)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

CREATE INDEX MIS_CDR_TEST_INDX1 ON MIS_CDR_TESTS
(TEST_NAME, FIRST_RESULT_ID, LAST_RESULT_ID)
LOGGING
TABLESPACE &&USERS_TABLESPACE;



