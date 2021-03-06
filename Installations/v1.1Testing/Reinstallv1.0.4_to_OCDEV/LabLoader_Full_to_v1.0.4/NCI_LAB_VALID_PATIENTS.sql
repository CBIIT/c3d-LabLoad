--
-- NCI_LAB_VALID_PATIENTS  (Table) 
--
CREATE TABLE NCI_LAB_VALID_PATIENTS
(
  PT_ID        VARCHAR2(200 BYTE),
  PT           VARCHAR2(10 BYTE),
  STUDY        VARCHAR2(14 BYTE),
  NCI_INST_CD  VARCHAR2(200 BYTE),
  LABORATORY   VARCHAR2(10 BYTE)
)
TABLESPACE &&USERS_TABLESPACE;

--
-- NLVP_IDX1  (Index) 
--
CREATE INDEX NLVP_IDX1 ON NCI_LAB_VALID_PATIENTS
(PT_ID, NCI_INST_CD)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

--
-- NLVP_IDX2  (Index) 
--
CREATE INDEX NLVP_IDX2 ON NCI_LAB_VALID_PATIENTS
(STUDY)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

--
-- NLVP_IDX3  (Index) 
--
CREATE INDEX NLVP_IDX3 ON NCI_LAB_VALID_PATIENTS
(PT_ID, LABORATORY)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

