--
-- MDLABS_STG  (Table) 
--
CREATE TABLE MDLABS_STG
(
  PROTOCOL              VARCHAR2(10 BYTE),
  ACCESSIONNUMBER       VARCHAR2(10 BYTE),
  OBX_OBSERVATIONDTIME  VARCHAR2(40 BYTE),
  LAB_NAME              VARCHAR2(100 BYTE),
  PROCEDURENAME         VARCHAR2(100 BYTE),
  OBSERVATIONVALUE      VARCHAR2(10 BYTE),
  UNITS                 VARCHAR2(10 BYTE),
  REFERENCERANGE        VARCHAR2(50 BYTE),
  DATE_CREATED          DATE,
  DATE_MODIFIED         DATE,
  CREATED_BY            VARCHAR2(240 BYTE),
  MODIFIED_BY           VARCHAR2(240 BYTE),
  RECORD_ID             NUMBER(6),
  LOAD_FLAG             VARCHAR2(6 BYTE)
)
TABLESPACE  &&USERS_TABLESPACE;


--
-- MD_LABS_TRG  (Trigger) 
--
CREATE OR REPLACE TRIGGER MD_LABS_TRG
BEFORE INSERT
ON MDLABS_STG
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
tmpVar NUMBER;

BEGIN
 If :new.load_flag is null then
    :new.load_flag := 'N';
 End If;

 IF :new.record_id IS NULL THEN
       SELECT MD_Labs_SEQ.NEXTVAL
       INTO :new.record_id
       FROM dual;
       IF SQL%notfound THEN
       raise_application_error(-20031,
           'Warning on Insert: The MDLABSSEQ sequence generator is not working');
       END IF;
 END IF;

End;
/
SHOW ERRORS;



--
-- NLB_MDLABS  (Trigger) 
--
CREATE OR REPLACE TRIGGER NLB_MDLABS
 BEFORE INSERT
 ON MDLABS_STG
  FOR EACH ROW
-- PL/SQL BLOCK
BEGIN

 if :new.CREATED_BY IS NULL THEN
   :new.CREATED_BY := user;
 END IF;
 :new.DATE_CREATED := sysdate;
END;
/
SHOW ERRORS;



--
-- NLB_MDLABS_US  (Trigger) 
--
CREATE OR REPLACE TRIGGER NLB_MDLABS_US
 BEFORE UPDATE
 ON MDLABS_STG
 FOR EACH ROW
BEGIN

    :new.MODIFIED_BY  := user;
    :new.DATE_MODIFIED := sysdate;
END;
/
SHOW ERRORS;



