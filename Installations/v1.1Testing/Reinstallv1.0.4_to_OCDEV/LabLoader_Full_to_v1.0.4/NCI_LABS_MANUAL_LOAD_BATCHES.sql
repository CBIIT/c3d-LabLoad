-- Drop table first
DROP TABLE NCI_LABS_MANUAL_LOAD_BATCHES;

-- create table
CREATE TABLE NCI_LABS_MANUAL_LOAD_BATCHES
(
  BATCH_ID        NUMBER(10),
  SUBMIT_BY       VARCHAR2(30 BYTE),
  SUBMIT_DATE     DATE,
  JOB_ID          NUMBER(10),
  JOB_START_DATE  DATE,
  JOB_STOP_DATE   DATE,
  BATCH_STATUS    VARCHAR2(1 BYTE)              DEFAULT 'N',
  STATUS_COMMENT  VARCHAR2(200 BYTE)            DEFAULT 'New Batch'
)
TABLESPACE USERS
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING;

CREATE INDEX NLMLB_IDX ON NCI_LABS_MANUAL_LOAD_BATCHES
(BATCH_ID)
LOGGING
TABLESPACE USERS
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

