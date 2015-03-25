--
-- NCI_LAB_MAPPING  (Table) 
--
CREATE TABLE NCI_LAB_MAPPING
(
  ID                 NUMBER(10),
  TEST_COMPONENT_ID  VARCHAR2(8 BYTE),
  TEST_CODE          VARCHAR2(12 BYTE),
  LABORATORY         VARCHAR2(10 BYTE),
  LAB_PANEL          VARCHAR2(50 BYTE),
  LAB_TEST           VARCHAR2(60 BYTE),
  OC_LAB_QUESTION    VARCHAR2(20 BYTE),
  DATE_CREATED       DATE,
  DATE_MODIFIED      DATE,
  CREATED_BY         VARCHAR2(30 BYTE),
  MODIFIED_BY        VARCHAR2(30 BYTE)
)
TABLESPACE &&USERS_TABLESPACE;

--
-- NCI_LAB_MAPPING_IDX  (Index) 
--
CREATE INDEX NCI_LAB_MAPPING_IDX ON NCI_LAB_MAPPING
(TEST_COMPONENT_ID, LABORATORY, OC_LAB_QUESTION)
LOGGING
TABLESPACE &&USERS_TABLESPACE;

--
-- NLM_BRI_TRG  (Trigger) 
--
CREATE OR REPLACE TRIGGER NLM_BRI_TRG
 BEFORE INSERT
 ON NCI_LAB_MAPPING 
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
-- PL/SQL BLOCK
BEGIN

    if :new.id is null then
      select NLM_seq.nextval
      into :new.id
      from dual;
   end if;
   if :new.CREATED_BY IS NULL THEN
   :new.CREATED_BY := user;
   END IF;
   :new.DATE_CREATED := sysdate;
END;
/
SHOW ERRORS;


--
-- NLM_BRU_TRG  (Trigger) 
--
CREATE OR REPLACE TRIGGER NLM_BRU_TRG
 BEFORE UPDATE
 ON NCI_LAB_MAPPING 
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
-- PL/SQL BLOCK
BEGIN

    :new.MODIFIED_BY  := user;
    :new.DATE_MODIFIED := sysdate;
END;
/
SHOW ERRORS;

