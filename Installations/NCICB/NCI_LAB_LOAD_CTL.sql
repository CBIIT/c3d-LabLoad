
CREATE TABLE NCI_LAB_LOAD_CTL
(
  OC_STUDY                   VARCHAR2(30 BYTE)  NOT NULL,
  OFF_STUDY_OFFSET_DAYS      NUMBER,
  STOP_LAB_LOAD_FLAG         VARCHAR2(1 BYTE)   DEFAULT 'N',
  DATE_CREATED               DATE,
  DATE_MODIFIED              DATE,
  CREATED_BY                 VARCHAR2(30 BYTE),
  MODIFIED_BY                VARCHAR2(30 BYTE),
  OFF_STUDY_DCM              VARCHAR2(30 BYTE),
  OFF_STUDY_QUEST            VARCHAR2(30 BYTE),
  LOAD_OTHER_LABS            VARCHAR2(1 BYTE),
  LABORATORY                 VARCHAR2(10 BYTE),
  BLANK_PRESTUDY_USE_ENROLL  VARCHAR2(1 BYTE),
  REVIEW_STUDY               VARCHAR2(1 BYTE),
  LABTESTNAME_IS_OCLABQUEST  VARCHAR2(1 BYTE),
  PRESTUDY_LAB_DATE_DCM      VARCHAR2(30 BYTE),
  PRESTUDY_LAB_DATE_QUEST    VARCHAR2(30 BYTE),
  PRESTUDY_OFFSET_DAYS       NUMBER,
  DATE_CHECK_CODE            VARCHAR2(4 BYTE),
  ENROLLMENT_DATE_DCM        VARCHAR2(30 BYTE),
  ENROLLMENT_DATE_QUEST      VARCHAR2(30 BYTE)
)
TABLESPACE &&USERS_TABLESPACE;


COMMENT ON COLUMN NCI_LAB_LOAD_CTL.ENROLLMENT_DATE_QUEST IS 'Question Name where Enrollment Date Question Resides';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.LOAD_OTHER_LABS IS '''Y'' will allow Non Repeat Defaults to be processed, ''N'' will marked them as an Error';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.BLANK_PRESTUDY_USE_ENROLL IS 'Use Enrollment Date when Prestudy Date is null';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.LABTESTNAME_IS_OCLABQUEST IS 'Use LABTEST_NAME to populate OC_LAB_QUESTION';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.OFF_STUDY_DCM IS 'What is the name of the DCM where the Off Study Question can be located';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.OFF_STUDY_QUEST IS 'What is the QUESTION that contains the Off Study Date';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.PRESTUDY_LAB_DATE_DCM IS 'DCM Name where PreStudy Lab Date Question Resides';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.PRESTUDY_LAB_DATE_QUEST IS 'Question Name where PreStudy Lab Date Question Resides';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.PRESTUDY_OFFSET_DAYS IS 'Days to add (+) or subtract (-) to PreStudy Lab Date prior to comparison';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.DATE_CHECK_CODE IS '"NONE" - No date check; "PRE" - PreStudy Only; "OFF" - OffStudy Only; "BOTH" - Check Pre and OffStudy';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.ENROLLMENT_DATE_DCM IS 'DCM Name where Enrollment Date Question Resides';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.REVIEW_STUDY IS '''Y'' Lab Test need reviewed via LLI prior to loading. ''N'' load Lab Tests without review.';


CREATE INDEX LAB_LOAD_CTL_IDX ON NCI_LAB_LOAD_CTL
(OC_STUDY)
LOGGING
TABLESPACE  &&USERS_TABLESPACE;


CREATE INDEX LLC_IDX ON NCI_LAB_LOAD_CTL
(OC_STUDY, REVIEW_STUDY)
LOGGING
TABLESPACE  &&USERS_TABLESPACE;


CREATE OR REPLACE TRIGGER LLC_BFI
BEFORE INSERT
ON NCI_LAB_LOAD_CTL 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

/******************************************************************************
   NAME:       llc_bfi
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        4/7/2004     Patrick Conrad  1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     llc_bfi
      Sysdate:         4/7/2004
      Date and Time:   4/7/2004, 12:22:45 PM, and 4/7/2004 12:22:45 PM
      Username:         (set in TOAD Options, Proc Templates)
      Table Name:      NCI_LAB_LOAD_CTL (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEGIN
   :NEW.Date_Created := SYSDATE;
   :NEW.Created_by := USER;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END llc_bfi;
/
SHOW ERRORS;



CREATE OR REPLACE TRIGGER LLC_BFU
BEFORE UPDATE
ON NCI_LAB_LOAD_CTL 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
/******************************************************************************
   NAME:       
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        4/7/2004    Patrick Conrad   1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     
      Sysdate:         4/7/2004
      Date and Time:   4/7/2004, 12:25:46 PM, and 4/7/2004 12:25:46 PM
      Username:         (set in TOAD Options, Proc Templates)
      Table Name:       (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEGIN
   :NEW.Date_Modified := SYSDATE;
   :NEW.Modified_By := USER;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END ;
/
SHOW ERRORS;



CREATE PUBLIC SYNONYM NCI_LAB_LOAD_CTL FOR NCI_LAB_LOAD_CTL;

GRANT SELECT ON  NCI_LAB_LOAD_CTL TO LABLOADER;

GRANT DELETE, INSERT, SELECT, UPDATE ON  NCI_LAB_LOAD_CTL TO LABLOADER_REVIEW;

GRANT DELETE, INSERT, SELECT, UPDATE ON  NCI_LAB_LOAD_CTL TO LABLOADER_ADMIN;


