
--
-- NCI_LAB_LOAD_PATIENT_LOAD  (Table) 
--
CREATE TABLE NCI_LAB_LOAD_PATIENT_LOAD
(
  PT_ID      VARCHAR2(15 BYTE)                  NOT NULL,
  LOAD_FLAG  VARCHAR2(1 BYTE)                   NOT NULL,
  LOAD_DATE  DATE
)
TABLESPACE  &&USERS_TABLESPACE;


--
-- NCI_LLPL_PATIENT_LOAD  (Index) 
--
CREATE UNIQUE INDEX NCI_LLPL_PATIENT_LOAD ON NCI_LAB_LOAD_PATIENT_LOAD
(PT_ID, LOAD_FLAG)
LOGGING
TABLESPACE  &&USERS_TABLESPACE;



