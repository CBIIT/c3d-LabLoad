
CREATE TABLE NCI_LABS_STUDY_LABORATORYS
(
  OC_STUDY     VARCHAR2(15 BYTE)                NOT NULL,
  LABORATORY   VARCHAR2(10 BYTE)                NOT NULL,
  CREATE_DATE  DATE,
  CREATE_USER  VARCHAR2(15 BYTE),
  MODIFY_DATE  DATE,
  MODIFY_USER  VARCHAR2(15 BYTE),
  ACTIVE_FLAG  VARCHAR2(1 BYTE)                 DEFAULT 'Y'                   NOT NULL
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING
/


CREATE UNIQUE INDEX NLSL_INDX1 ON NCI_LABS_STUDY_LABORATORYS
(OC_STUDY, LABORATORY)
LOGGING
NOPARALLEL
/


CREATE OR REPLACE TRIGGER NLSL_BFI
BEFORE INSERT
ON OPS$BDL.NCI_LABS_STUDY_LABORATORYS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

BEGIN
   :NEW.Create_Date := SYSDATE;
   :NEW.Create_User := USER;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END ;
/
SHOW ERRORS;



CREATE OR REPLACE TRIGGER NLSL_BFU
BEFORE UPDATE
ON OPS$BDL.NCI_LABS_STUDY_LABORATORYS
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE

BEGIN

   :NEW.MODIFY_Date := SYSDATE;
   :NEW.MODIFY_User := USER;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END NLSL_BFU;
/
SHOW ERRORS;




Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('99_C_0023', 'NETTRIALS', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('LOMBARDI_02452', 'GEORGETOWN', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('LOMBARDI_04251', 'GEORGETOWN', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('2003_0919', 'MDANDERSON', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('UPCC_07403', 'UPCC', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('LOMBARDI_03058', 'GEORGETOWN', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('COTC001', 'IDEXX', TO_DATE('11/30/2011 14:48:28', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('ALL', 'CDW', TO_DATE('11/30/2011 14:48:45', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
Insert into NCI_LABS_STUDY_LABORATORYS
   (OC_STUDY, LABORATORY, CREATE_DATE, CREATE_USER, MODIFY_DATE, 
    MODIFY_USER, ACTIVE_FLAG)
 Values
   ('ALL', 'BTRIS', TO_DATE('11/30/2011 14:48:53', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL', NULL, 
    NULL, 'Y');
COMMIT;

