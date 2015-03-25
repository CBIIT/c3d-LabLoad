
--
-- NCI_STUDY_LABDCM_EVENTS_TB  (Table) 
--
CREATE TABLE NCI_STUDY_LABDCM_EVENTS_TB
(
  OC_STUDY         NUMBER(10),
  STUDY            VARCHAR2(15 BYTE),
  DCM_NAME         VARCHAR2(16 BYTE),
  SUBSET_NAME      VARCHAR2(8 BYTE),
  QUESTION_NAME    VARCHAR2(20 BYTE),
  CPE_NAME         VARCHAR2(16 BYTE),
  REPEAT_SN        NUMBER(4),
  OC_LAB_QUESTION  VARCHAR2(200 BYTE),
  DISPLAY_SN       NUMBER(4)
)
TABLESPACE USERS
LOGGING 
NOCACHE
NOPARALLEL;


--
-- NSLDET_IDX1  (Index) 
--
--  Dependencies: 
--   NCI_STUDY_LABDCM_EVENTS_TB (Table)
--
CREATE INDEX NSLDET_IDX1 ON NCI_STUDY_LABDCM_EVENTS_TB
(STUDY, DCM_NAME, SUBSET_NAME, QUESTION_NAME, REPEAT_SN, 
OC_LAB_QUESTION)
LOGGING
TABLESPACE USERS
NOPARALLEL;


--
-- NSLDET_IDX2  (Index) 
--
--  Dependencies: 
--   NCI_STUDY_LABDCM_EVENTS_TB (Table)
--
CREATE INDEX NSLDET_IDX2 ON NCI_STUDY_LABDCM_EVENTS_TB
(STUDY, OC_LAB_QUESTION, DISPLAY_SN)
LOGGING
TABLESPACE USERS
NOPARALLEL;



