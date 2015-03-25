create or replace PACKAGE insert_lab_data
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*     Author: Original Unknown                                                      */
/*       Date: Original Unknown                                                      */
/*Description: Creates Batch Data Load records into a table.                         */
/*             (Original Description Missing)                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*  Modification History                                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
AS
PROCEDURE insert_record (
  investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, dcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, qual_value IN char
, study IN char
, tableid IN char);

PROCEDURE save_repeat (
repeat_sn IN number);

PROCEDURE insert_missing_responses (
  investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, ipdcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, qual_value IN char
, ipstudy IN char
, tableid IN char);

PROCEDURE insert_missing_DCMS;

PROCEDURE delete_repeats;

END insert_lab_data;
/

show errors

create or replace
PACKAGE BODY insert_lab_data
AS
PROCEDURE insert_record (
 investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, dcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, qual_value in char
, study IN char
, tableid IN char)
IS

BEGIN
        INSERT INTO BDL_TEMP_FILES
        (ID,
        INVESTIGATOR,
        SITE,
        PATIENT,
        DOCUMENT_NO,
        PLANNED_EVENT,
        SUBEVENT_NO,
        DCI_DATE,
        DCI_TIME,
        DCI_NAME,
        DCM_NAME,
        DCM_SUBSET,
        DCM_QUESGRP,
        DCM_QUES,
        DCM_OCCUR,
        REPEAT_SN,
        VALUETEXT,
        DATA_COMMENT,
        QUALIFYING_VALUE,
        STUDY
        )
        VALUES (
        tableid,
        investigator,
        site,
        patient,
        document_no,
        planned_event,
        subevent_no,
        dci_date,
        dci_time,
        dci_name,
        dcm_name,
        dcm_subset,
        dcm_quesgrp,
        dcm_ques,
        '0',
        repeat_sn,
        valuetext,
        null,
        qual_value,
        study);

        COMMIT;

END insert_record;

PROCEDURE save_repeat (
 repeat_sn IN number)
IS

BEGIN
        INSERT INTO BDL_RESPONSE_REPEATS (REPEAT_SN)
        VALUES (repeat_sn);

        COMMIT;

END save_repeat;

PROCEDURE insert_missing_responses (
 investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, ipdcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, qual_value in char
, ipstudy IN char
, tableid IN char)
IS

BEGIN
DECLARE

CURSOR c1 is
        SELECT v.repeat_sn repeat_seq
,       substr(v.oc_lab_question,1,20) value_text
        FROM CLINICAL_STUDIES S,
                NCI_STUDY_DCMS_VW V
        WHERE S.study = ipstudy
        AND V.oc_study = S.clinical_study_id
        AND V.dcm_name = ipdcm_name
        AND V.subset_name = dcm_subset
        and v.cpe_name = planned_event  -- prc 04/29/2004: Need to limit it to the event.
        AND V.QUESTION_NAME = 'LPARM'
        AND V.REPEAT_SN NOT IN (SELECT repeat_sn FROM BDL_RESPONSE_REPEATS)
        ORDER BY v.repeat_sn;


c1_record c1%ROWTYPE;

  BEGIN

  Log_Util.LogMessage('IMR - dci_name="'||dci_name||'"; dci_date='||dci_date||'; dci_time='||dci_time);
  Log_Util.LogMessage('IMR - ipdcm_name="'||ipdcm_name||'"; dcm_subset="'||dcm_subset||'"');
  Log_Util.LogMessage('IMR - Qualifying Value="'||qual_value||'".');
  Log_Util.LogMessage('IMR - DCM_quesgrp="'||DCM_quesgrp||'"; DCM_ques="'||DCM_ques||'"');
  Log_Util.LogMessage('IMR - repeat_sn='||to_char(repeat_sn));
  Log_Util.LogMessage('IMR - ipstudy="'||ipstudy||'"; patient='||patient);
  Log_Util.LogMessage('IMR - valuetext='||valuetext);

  OPEN c1;
  LOOP
  FETCH c1 INTO c1_record;

  EXIT WHEN c1%NOTFOUND;
  Log_Util.LogMessage('IMR - c1_record.repeat_seq='||lpad(c1_record.repeat_seq,4)||
                            '; c1_record.value_text='||c1_record.value_text);

        INSERT INTO BDL_TEMP_FILES
        (ID,
        INVESTIGATOR,
        SITE,
        PATIENT,
        DOCUMENT_NO,
        PLANNED_EVENT,
        SUBEVENT_NO,
        DCI_DATE,
        DCI_TIME,
        DCI_NAME,
        DCM_NAME,
        DCM_SUBSET,
        DCM_QUESGRP,
        DCM_QUES,
        DCM_OCCUR,
        REPEAT_SN,
        VALUETEXT,
        DATA_COMMENT,
        QUALIFYING_VALUE,
        STUDY
        )
        VALUES (
        tableid,
        investigator,
        site,
        patient,
        document_no,
        planned_event,
        subevent_no,
        dci_date,
        dci_time,
        dci_name,
        ipdcm_name,
        dcm_subset,
        dcm_quesgrp,
        'LPARM',
        '0',
        c1_record.repeat_seq,
        c1_record.value_text,
        null,
        qual_value,
        ipstudy);

        COMMIT;

  END LOOP;

  CLOSE c1;

  END;

END insert_missing_responses;

PROCEDURE insert_missing_DCMs
IS
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*     Author: Patrick Conrad - Ekagra                                               */
/*       Date: 01/04/2006                                                            */
/*Description: This procedure is used to create a question for each DCM that belongs */
/*             to a DCI for a Lab Test Records that is to be loaded  This is an      */
/*             enhancement due to OC 4.5.1 upgrade that causes an error in RDC       */
/*             (Remote Data Capture) when a DCI has missing DCMs.  This usually      */
/*             when DCIs are loaded through Batch Data Loading.                      */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*  Modification History                                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

   CURSOR c1 (X_Study Varchar2, X_DCI_Name Varchar2, X_DCM_Name Varchar2,
              X_DCI_Date Varchar2, X_DCI_Time Varchar2, x_Patient Varchar2) is
   select ri.CLIN_PLAN_EVE_NAME PLANNED_EVENT,
          ri.SUBEVENT_NUMBER SUBEVENT_NO,
          dq.question_name quest_name,
          dm.QUAL_QUESTION_VALUE_TEXT QUAL_VALUE,
          dqg.name DCM_QUESGRP,
          NULL Value_Text,
          d.name DCM_NAME,
          d.subset_name DCMSUBST,
          decode(dm.EVENT_DATE_IS_DCI_DATE_FLAG,'Y',ri.DCI_DATE, NULL) DCI_DATE,
          decode(dm.COLLECT_EVENT_TIME_FLAG, 'Y', ri.DCI_TIME, NULL) DCI_TIME
     from received_dcis ri,
          dci_modules dm,
          dcms d,
          dcis i,
          dcm_question_groups dqg,
          dcm_questions dq
    where ri.received_dci_status_code='BATCH LOADED'
      and d.dcm_id=dm.DCM_ID
      and d.DCM_LAYOUT_SN=dm.DCM_LAYOUT_SN
      and d.DCM_SUBSET_SN=dm.DCM_SUBSET_SN
      and dqg.DCM_ID=d.DCM_ID
      and dqg.DCM_QUE_GRP_DCM_LAYOUT_SN=d.DCM_LAYOUT_SN
      and dqg.DCM_QUE_GRP_DCM_SUBSET_SN=d.DCM_SUBSET_SN
      and dqg.DISPLAY_SN=1
      and dq.DCM_QUESTION_GROUP_ID=dqg.DCM_QUESTION_GRP_ID
      and dq.DISPLAY_SN=1
      and dq.derived_flag = 'N'
      and ri.DCI_ID=i.DCI_ID
      and i.DCI_ID=dm.DCI_ID
      and i.dci_id in (select dci_id from dci_modules group by dci_id having count(*)>1)
      and i.domain = x_Study
      and i.name = x_DCI_Name
      and d.name <> x_DCM_Name
      and ri.DCI_DATE = x_DCI_DATE
      and ri.DCI_TIME = x_DCI_TIME
      and ri.patient  = x_Patient
      and d.dcm_id not in (select dcm_id from received_dcms a
                           where a.RECEIVED_DCI_ID = ri.RECEIVED_DCI_ID);

   c1_rec c1%ROWTYPE;


BEGIN
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('MISSDCMS_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
   Else
     Log_Util.LogMessage('IMDCMs: Starting Insert Missing DCMS');
   End If;

   Log_Util.LogMessage('IMDCMs: Deleting existing "EXTRA_DCMS" records from BDL_TEMP_FILES.');
   Delete from bdl_temp_files where id = 'EXTRA_DCMS';
   Log_Util.LogMessage('IMDCMs: '||to_char(SQL%RowCount)||
                       ' "EXTRA_DCMS" records successfully deleted from BDL_TEMP_FILES');

   Log_Util.LogMessage('IMDCMs: Querying for BDL_TEMP_FILES records needing extra DCMs.');

   For X_REc in (select distinct study, patient, DCI_NAME, DCM_NAME, DCI_DATE, DCI_TIME from bdl_temp_files) Loop

      Log_Util.LogMessage('IMDCMs: Query Found - study="'||X_Rec.study||'"; Patient="'||X_Rec.Patient||'"; '||
                                  'dci_name="'||X_Rec.dci_name||'"; dcm_name="'||X_Rec.dcm_name||'"; '||
                                  'dci_date="'||X_Rec.dci_date||'"; dci_time="'||X_Rec.dci_time||'"');

      OPEN c1 (X_Rec.Study, X_Rec.DCI_Name, X_Rec.DCM_Name,
               X_Rec.DCI_Date, X_Rec.DCI_Time, X_Rec.Patient);
      LOOP
         FETCH c1 INTO c1_rec;

         EXIT WHEN c1%NOTFOUND;
         Log_Util.LogMessage('IMDCMs: Found Missing - DCM="'||c1_rec.DCM_NAME||'";  Question="'||c1_rec.quest_name||'"');
         Log_Util.LogMessage('IMDCMs:                 SubEvent_No="'||c1_rec.SubEvent_no||'"; '||
                                             'Planned_Event="'||c1_rec.PLANNED_EVENT||'"');

         INSERT INTO BDL_TEMP_FILES (
           ID,                    INVESTIGATOR,        SITE,               PATIENT,           DOCUMENT_NO,
           PLANNED_EVENT,         SUBEVENT_NO,         DCI_DATE,           DCI_TIME,          DCI_NAME,
           DCM_NAME,              DCM_SUBSET,          DCM_QUESGRP,        DCM_QUES,          DCM_OCCUR,
           REPEAT_SN,             VALUETEXT,           DATA_COMMENT,       QUALIFYING_VALUE,  STUDY        )
         VALUES (
           'EXTRA_DCMS',          NULL,                NULL,               X_Rec.Patient,     NULL,
           C1_Rec.Planned_Event,  C1_Rec.subevent_no,  C1_Rec.DCI_DATE,    C1_Rec.DCI_TIME,   X_Rec.dci_name,
           C1_Rec.dcm_name,       C1_Rec.dcmsubst,     C1_Rec.dcm_quesgrp, C1_Rec.quest_name, '0',
           1,                     C1_Rec.value_text,   NULL,               c1_Rec.QUAL_VALUE, X_Rec.study);

         COMMIT;

      END LOOP;

      CLOSE c1;

   End Loop;
   Log_Util.LogMessage('IMDCMs: Finished querying for BDL_TEMP_FILES records needing extra DCMs.');

   Log_Util.LogMessage('IMDCMs: Deleting NON-"EXTRA_DCMS" records from BDL_TEMP_FILES.');
   Delete from bdl_temp_files where id <> 'EXTRA_DCMS';
   Log_Util.LogMessage('IMDCMs: '||to_char(SQL%RowCount)||
                       ' NON-"EXTRA_DCMS" records successfully deleted from BDL_TEMP_FILES');

   COMMIT;

   Log_Util.LogMessage('IMDCMs: Finished Insert Missing DCMS');

END insert_missing_DCMs;


PROCEDURE delete_repeats
IS

BEGIN
        DELETE from BDL_RESPONSE_REPEATS;

        COMMIT;

END delete_repeats;

END insert_lab_data;
/

sho errors
