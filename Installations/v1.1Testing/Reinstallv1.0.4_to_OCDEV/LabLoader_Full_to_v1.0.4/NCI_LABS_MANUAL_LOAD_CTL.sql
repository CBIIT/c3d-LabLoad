-- Drop table first
DROP TABLE NCI_LABS_MANUAL_LOAD_CTL;


-- create table
CREATE TABLE NCI_LABS_MANUAL_LOAD_CTL
(
  STUDY                   VARCHAR2(200 BYTE),
  HOLD_DATA_CHANGES       VARCHAR2(4000 BYTE),
  AUTO_CHANGE_HOLD_DATA   VARCHAR2(1 BYTE),
  AUTO_MOVE_TO_STAGE      VARCHAR2(1 BYTE),
  AUTO_CHANGE_STAGE_DATA  VARCHAR2(1 BYTE),
  AUTO_MOVE_TO_LOADER     VARCHAR2(1 BYTE),
  AUTO_LOAD_TO_OC         VARCHAR2(1 BYTE),
  CREATE_USER             VARCHAR2(30 BYTE),
  CREATE_DATE             DATE,
  MODIFY_USER             VARCHAR2(30 BYTE),
  MODIFY_DATE             DATE,
  STAGE_DATA_CHANGES      VARCHAR2(4000 BYTE),
  INBOUND_STUDY           VARCHAR2(200 BYTE)
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

CREATE UNIQUE INDEX ML_CTL_PK ON NCI_LABS_MANUAL_LOAD_CTL
(STUDY)
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

ALTER TABLE NCI_LABS_MANUAL_LOAD_CTL ADD (
  CONSTRAINT ML_CTL_PK
 PRIMARY KEY
 (STUDY)
    USING INDEX 
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
               ));


