create or replace
PACKAGE insert_lab_data
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
, ipstudy IN char
, tableid IN char);

PROCEDURE delete_repeats;
PROCEDURE identify_duplicate_records;

END insert_lab_data;
/
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
        null,
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

  Log_Util.LogMessage('IMR - dci_name='||dci_name);
  Log_Util.LogMessage('IMR - dci_date='||dci_date  );
  Log_Util.LogMessage('IMR - dci_time='||dci_time    );
  Log_Util.LogMessage('IMR - ipdcm_name='||ipdcm_name );
  Log_Util.LogMessage('IMR - patient='||patient         );
  Log_Util.LogMessage('IMR - dcm_subset='||dcm_subset     );
  Log_Util.LogMessage('IMR - DCM_quesgrp='||DCM_quesgrp     );
  Log_Util.LogMessage('IMR - DCM_ques='||DCM_ques             );
  Log_Util.LogMessage('IMR - repeat_sn='||to_char(repeat_sn)    );
  Log_Util.LogMessage('IMR - ipstudy='||ipstudy                   );
  Log_Util.LogMessage('IMR - valuetext='||valuetext                 );
  
  
  
  


  OPEN c1;
  LOOP
  FETCH c1 INTO c1_record;
  
  EXIT WHEN c1%NOTFOUND;
  Log_Util.LogMessage('IMR - c1_record.repeat_seq='||c1_record.repeat_seq); 
  Log_Util.LogMessage('IMR - c1_record.value_text='||c1_record.value_text);

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
        null,
        ipstudy);

        COMMIT;

  END LOOP;

  CLOSE c1;

  END;

END insert_missing_responses;

PROCEDURE delete_repeats
IS

BEGIN
        DELETE from BDL_RESPONSE_REPEATS;

        COMMIT;

END delete_repeats;

PROCEDURE identify_duplicate_records IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */  
  /* Modification History:                                               */ 
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */ 
  /* PRC - Ekagra - 04/02/2004:                                          */ 
  /* Modified Cursor to incorporate Study when determining if the record */ 
  /* to be loaded is a duplicate.  Added Code to support this new method */ 
  /* Also added code to report an error message when setting the load    */
  /* flag to 'X'                                                         */ 
  /* Also cleaned this section of code for readability.                  */
  /* PRC - Ekagra - 04/28/2004:                                          */
  /* Modified cursor to so that an index could be utilized. This routine */
  /* was identified as having an execution time of over 1 hour when the  */
  /* number of 'NEW' records was in the 30K range.  Additionally, an     */
  /* index was added to speed up the routine (NCI_LABS_IDX5)             */
  /* ALSO                                                                */
  /* Found that this routine could be simplified by just identifying     */
  /* PRC - 09/07/2004:                                                   */
  /* Found error in routine, where all exact duplicates of "to be loaded"*/
  /* records where being marked.  Corrected error, now only 2+ records   */
  /* are being marked as exact dupes                                     */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 11/17/2004:                                                   */
  /* Added counter and Log Message for counter.                          */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  
  last_oc_study   varchar2(20); -- prc 04/02/2004 
  last_patient_id varchar2(10);
  last_oc_patient_pos nci_labs.oc_patient_pos%type; -- prc 09/27/04 : 
  last_sample_dt  varchar2(10);
  last_labtest    nci_labs.labtest_name%type;  -- prc 09/24/04 : Converted Type
  last_question   nci_labs.oc_lab_question%type;  -- prc 10/26/04 : Added Question
  last_result     varchar2(20);
  last_record_id  varchar2(20);
  first_patient   char(1);
  
  X_cnt           number := 0; -- prc 11/17/04 : Added Counter.

  CURSOR c1 is
  select  a.record_id
         ,b.record_id loaded_rec_id
         ,a.oc_study             -- prc 04/02/2004
         ,a.patient_id
         ,a.sample_datetime
         ,a.labtest_name labtest_name
         ,a.result
         ,a.unit
         ,a.load_flag
    from nci_labs a,
         nci_labs b
   where a.oc_study   = b.oc_study 
     and a.patient_id = b.patient_id
     and a.sample_datetime = b.sample_datetime
     and a.labtest_name = b.labtest_name
     and a.result = b.result
     and nvl(a.unit,'~')   = nvl(b.unit,'~')
     and a.LOAD_FLAG IN ('R','N','D')
     and b.load_flag in ('C');
     
   Cursor C2 is
     select  a.record_id
            --,b.record_id matching_rec_id -- prc 09/07/04 (not needed)
            ,a.oc_study             -- prc 04/02/2004
            ,a.patient_id
            ,a.oc_patient_pos
            ,a.sample_datetime
            ,a.labtest_name labtest_name
            ,a.oc_lab_question l_question  -- prc 10/26/04 added question
            ,a.result
            ,a.unit
            ,a.load_flag
       from nci_labs a
      where a.LOAD_FLAG IN ('R','N','D')
      order by a.oc_study, a.oc_patient_pos, a.sample_datetime, 
               a.oc_lab_question, a.result, a.unit, a.patient_id; --changed to oc_lab_question from labtes_name

/*    Removed INVALID where clause from above.  Also remove "b" reference to NIC_LABS.  
      where a.oc_study   = b.oc_study 
        and a.patient_id = b.patient_id
        and a.sample_datetime = b.sample_datetime
        and a.labtest_name = b.labtest_name
        and a.result = b.result
        and nvl(a.unit,'~')   = nvl(b.unit,'~')
        and a.LOAD_FLAG IN ('R','N','D')
        and b.load_flag in ('R','N','D')
        and a.record_id <> b.record_id
      order by a.oc_study, a.patient_id, a.sample_datetime, a.result, a.unit;*/

  c1_record c1%ROWTYPE;
  c2_record c2%ROWTYPE;

BEGIN


  Log_Util.LogMessage('IDR - Checking Exact Dup. against already loaded.');

  first_patient := 'Y';
  x_cnt := 0;
  OPEN c1;
  LOOP
    FETCH c1 INTO c1_record;
    EXIT WHEN c1%NOTFOUND;

    update nci_labs 
       set load_flag = 'X', 
           error_reason = 'Exact Record Match Error with Loaded ('||c1_record.loaded_rec_id||')'
     where oc_study = c1_record.oc_study
       and record_id = c1_record.record_id;

    x_Cnt := X_Cnt + 1;
  END LOOP;

  CLOSE c1;
  Log_Util.LogMessage('IDR - Found '||to_char(X_cnt)||' "Exact Dup. against already loaded" records. ');

  Log_Util.LogMessage('IDR - Checking Exact Dup. against to be loaded records.');
  first_patient := 'Y';
  x_cnt := 0;
  
  last_oc_study   := '~';
  last_patient_id := '0';
  last_oc_patient_pos := 0;
  last_sample_dt  := '~';
  last_labtest    := '~';
  last_question   := '~';
  last_result     := '~';
  last_Record_id  := '0';

  OPEN c2;
  LOOP
    FETCH c2 INTO c2_record;
    EXIT WHEN c2%NOTFOUND;

    --Log_Util.LogMessage('IDR - LastPat="'||Last_patient_id||'"  PatID="'||c2_record.patient_id||'".');
    --Log_Util.LogMessage('IDR - LastREC="'||Last_Record_Id||'"  ThisRec="'||c2_record.Record_id||'".');
  
 --   if (first_patient = 'Y') then
 --      Log_Util.LogMessage('IDR - Set First_Patient to "N".');
 --      first_patient := 'N';
 --   else -- prc 04/02/2004
 --      if (c2_RECORD.oc_study || c2_record.oc_patient_pos || c2_record.sample_datetime || 
 --          c2_record.labtest_name || c2_record.result) =
 --         (last_oc_study || last_oc_patient_pos || last_sample_dt || 
 --          last_labtest || last_result) then
 
       if (c2_RECORD.oc_study       = last_oc_study)       AND
          (c2_record.oc_patient_pos = last_oc_patient_pos) AND
          (c2_record.sample_datetime= last_sample_dt)      AND
          (c2_record.l_question     = last_question)       AND
          (c2_record.result         = last_result)
       then
          --Log_Util.LogMessage('IDR - Equal, Setting "X".');
          --Log_Util.LogMessage('IDR - '||c2_RECORD.oc_study || c2_record.patient_id || c2_record.sample_datetime || 
          --                              c2_record.labtest_name || c2_record.result);
          --Log_Util.LogMessage('IDR - '||last_oc_study || last_patient_id || last_sample_dt || 
          --                              last_labtest || last_result);
          update nci_labs 
             set load_flag = 'X', 
                 error_reason = 'Exact Record Match Error for ('||Last_Record_Id||')'
           where oc_study = c2_record.oc_study
             and record_id = c2_record.record_id;
             
          x_cnt := x_cnt + 1;
       Else
          Null;
          --Log_Util.LogMessage('IDR - NOT Equal, Skipping "X".');
          --Log_Util.LogMessage('IDR - '||c2_RECORD.oc_study || c2_record.patient_id || c2_record.sample_datetime || 
          --                              c2_record.labtest_name || c2_record.result);
          --Log_Util.LogMessage('IDR - '||last_oc_study || last_patient_id || last_sample_dt || 
          --                              last_labtest || last_result);
       end if;
 --   end if;

    last_oc_study   := c2_record.oc_study;
    last_patient_id := c2_record.patient_id;
    last_oc_patient_pos := c2_record.oc_patient_pos;
    last_sample_dt  := c2_record.sample_datetime;
    last_labtest    := c2_record.labtest_name;
    last_question   := c2_record.l_question;
    last_result     := c2_record.result;
    last_Record_id  := c2_record.Record_id;


  END LOOP;

  CLOSE c2;
  Log_Util.LogMessage('IDR - Found '||to_char(X_cnt)||' "Exact Dup. against to be loaded" records. ');

END identify_duplicate_records;

END insert_lab_data;
/
