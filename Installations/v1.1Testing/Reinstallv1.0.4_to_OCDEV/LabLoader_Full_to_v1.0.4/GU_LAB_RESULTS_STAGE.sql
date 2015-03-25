--
-- GU_LAB_RESULTS_STAGE  (Table) 
--
CREATE TABLE GU_LAB_RESULTS_STAGE
(
  MRN                VARCHAR2(20 BYTE),
  SHORT_NAME         VARCHAR2(40 BYTE),
  LONG_NAME          VARCHAR2(100 BYTE),
  SAMPLE_DATE_RAW    VARCHAR2(15 BYTE),
  SAMPLE_TIME_RAW    VARCHAR2(15 BYTE),
  RESULT             VARCHAR2(15 BYTE),
  HI_LOW             VARCHAR2(20 BYTE),
  RANGE              VARCHAR2(20 BYTE),
  STUDY_NO           VARCHAR2(30 BYTE),
  INITIALS           VARCHAR2(10 BYTE),
  DEPT               VARCHAR2(30 BYTE),
  UNITS_RAW          VARCHAR2(30 BYTE),
  CREATE_DATE        DATE,
  CREATE_USER        VARCHAR2(30 BYTE),
  LOAD_FLAG          VARCHAR2(1 BYTE),
  SAMPLE_DATETIME    DATE,
  PROCESS_DATE       DATE,
  TEST_COMPONENT_ID  VARCHAR2(10 BYTE),
  C3DLABNAME         VARCHAR2(30 BYTE),
  GU_LAB_ID          VARCHAR2(10 BYTE),
  RECORD_ID          NUMBER(10)
)
TABLESPACE &&USERS_TABLESPACE;


--
-- BRI_GLRS_TRG  (Trigger) 
--
CREATE OR REPLACE TRIGGER BRI_GLRS_TRG
BEFORE INSERT
ON GU_LAB_RESULTS_STAGE
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
tmpVar NUMBER;
 
BEGIN
 If :new.load_flag is null then
    :new.load_flag := 'N';
 End If;

 IF :new.record_id IS NULL THEN
       SELECT GLRS_SEQ.NEXTVAL
       INTO :new.record_id
       FROM dual;
       IF SQL%notfound THEN
       raise_application_error(-20031,
           'Warning on Insert: The GLRS sequence generator is not working');
       END IF;
 END IF;
 if :new.CREATE_USER IS NULL THEN
   :new.CREATE_USER := user;
 END IF;
 :new.CREATE_DATE := sysdate;

End;
/
SHOW ERRORS;




