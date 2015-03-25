CREATE OR REPLACE PROCEDURE load_lab_results_upd (v_Type in Varchar2, v_Study in Varchar2 default '%' ) AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick COnrad                                                        */
  /*       Date: 08/09/2005                                                            */
  /*Description: Lab Load Results for UPDATE Lab Test Records                          */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC 06/06/2006: Altered code so that SubEvent_Number is retrieved and used as part*/
  /*                 of the BDL file.  By doing this, BDL does not have to look up the */
  /*                 subevent number, and  is able to bypass the DCI Date/Time matching*/
  /*                 DCM Date/Time error.  This also allows for the removal of the     */
  /*                 same error in the Lab Loader.                                     */
  /* ALSO: Made modifications to the Log Messages created during the subevent number   */
  /*       retrieval for cosmetic as well as destriptive reasons.                      */
  /* NOTE: This code could use a bit of clean-up for readability.                      */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  tableid         varchar2(20);
  investigator    varchar2(10);
  site            varchar2(10);
  S_dci_name      varchar2(50);
  S_dcm_id        number(10);
  S_dcm_name      varchar2(50);
  S_dcm_subset    varchar2(50);
  dcm_quesgrp     varchar2(50);
  dcm_ques        varchar2(50);
  planned_event   varchar2(40);
  c1valuetext     varchar2(200);
  subevent        number(2);
  document_no     varchar2(20);
  xrepeat_sn      number(4);
  qname           varchar2(200);
  LoadFlag        Boolean := TRUE;  -- prc 08/23/06: Need flag to designate unloadable record
  last_oc_lab_panel     varchar2(20);
  last_oc_lab_subset    varchar2(12);
  last_oc_patient_pos   varchar2(12);
  last_sample_datetime  varchar2(10);
  last_oc_lab_question  varchar2(20);
  last_study            varchar2(20);
  v_repeat_add  number(4) := 0;
  CURSOR c1 is
    SELECT record_id
          ,patient_id
          ,patient_name
          ,sample_datetime
          ,TO_CHAR(to_date(substr(lpad(sample_datetime, 10, 0), 1, 6)
                          ,'MMDDRR') -- PRC 07/25/03
                  ,'YYYYMMDD') vdate
          ,substr(lpad(sample_datetime, 10, 0), 7, 4) || '00' vtime
          ,laboratory
          ,labtest_name
          ,result
          ,unit
          ,normal_value
          ,panel_name
          ,lab_grade
          ,oc_lab_panel
          ,oc_lab_subset
          ,oc_lab_question
          ,oc_lab_event
          ,qualifying_value
          ,decode(comments
                 ,null
                 ,'N/A'
                 ,SUBSTR(TRANSLATE(comments, ',', ' '), 1, 20)) comm
          ,oc_patient_pos
          ,test_component_id
          ,oc_study
          ,s.clinical_study_id study_id
      FROM nci_labs n, clinical_studies s
     WHERE OC_LAB_PANEL is not null
       AND LOAD_FLAG = v_type
       AND n.oc_study = s.study
       AND S.Study like nvl(v_study,'%')
     ORDER BY n.oc_study
             ,oc_lab_panel
             ,oc_lab_subset
             ,oc_patient_pos
             ,vdate
             ,vtime
             ,oc_lab_question
             ,unit;
  c1_record c1%ROWTYPE;
  Procedure Check_and_Set_Field (
             i_investigator IN char
            ,i_site IN char
            ,i_patient IN char
            ,i_document_no IN char
            ,i_planned_event IN char
            ,i_subevent_no IN number
            ,i_dci_date IN char
            ,i_dci_time IN char
            ,i_dci_name IN char
            ,i_dcm_name IN char
            ,i_dcm_subset IN char
            ,i_dcm_quesgrp IN char
            ,i_dcm_ques IN char
            ,i_repeat_sn IN number
            ,i_valuetext IN char
            ,i_qual_value in char
            ,i_study IN char
            ,i_tableid IN char) is
    xfound Varchar2(1);
  Begin
     -- There are occassions when the TEMPLATE is not followed, and certain
     -- questions do not exist in the Question Group, so this routine checks
     -- to see if the question exists before adding it to the batch data
     Select distinct 'Y'
       into xfound
       from nci_study_all_dcms_events_vw a
      where a.oc_study = i_study
        and a.dcm_name = i_dcm_name
        and a.subset_name = i_dcm_subset
        and a.cpe_name    = i_planned_event
        and a.question_name = i_dcm_ques;
     If xfound = 'Y' Then
        -- if found, it is a valid question, so add it.
        insert_lab_data.insert_record(i_investigator
                                     ,i_site
                                     ,i_patient
                                     ,i_document_no
                                     ,i_planned_event
                                     ,i_subevent_no
                                     ,i_dci_date
                                     ,i_dci_time
                                     ,i_dci_name
                                     ,i_dcm_name
                                     ,i_dcm_subset
                                     ,i_dcm_quesgrp
                                     ,i_dcm_ques
                                     ,i_repeat_sn
                                     ,i_valuetext
                                     ,i_qual_value
                                     ,i_study
                                     ,i_tableid);
     End If;
  Exception
     -- it is not a valid question, so ignore it.
     When Others Then Null;
  End;
  Procedure Insert_Record is
  Begin
     -- Set Constants
      dcm_quesgrp := 'LAB';
      investigator:= Null;
      site        := Null;
      document_no := Null;
      --subevent    := Null;
      tableid     := c1_record.oc_lab_panel;
      -- Set Response Specific Value
      dcm_ques    := 'LPARM';
      c1valuetext := c1_record.oc_lab_question;
      -- Insert Response
      insert_lab_data.insert_record(investigator
                                    ,site
                                    ,c1_record.oc_patient_pos
                                    ,document_no
                                    ,planned_event
                                    ,subevent
                                    ,c1_record.vdate
                                    ,c1_record.vtime
                                    ,S_dci_name
                                    ,S_dcm_name
                                    ,S_dcm_subset
                                    ,dcm_quesgrp
                                    ,dcm_ques
                                    ,xrepeat_sn
                                    ,c1valuetext
                                    ,c1_record.qualifying_value
                                    ,c1_record.oc_study
                                    ,tableid);
      dcm_ques    := 'LVALUE';
      c1valuetext := c1_record.result;
      insert_lab_data.insert_record(investigator
                                    ,site
                                    ,c1_record.oc_patient_pos
                                    ,document_no
                                    ,planned_event
                                    ,subevent
                                    ,c1_record.vdate
                                    ,c1_record.vtime
                                    ,S_dci_name
                                    ,S_dcm_name
                                    ,S_dcm_subset
                                    ,dcm_quesgrp
                                    ,dcm_ques
                                    ,xrepeat_sn
                                    ,c1valuetext
                                    ,c1_record.qualifying_value
                                    ,c1_record.oc_study
                                    ,tableid);
      dcm_ques    := 'LAB_UOM';
      c1valuetext := c1_record.unit;
      Check_and_Set_Field (investigator
                           ,site
                           ,c1_record.oc_patient_pos
                           ,document_no
                           ,planned_event
                           ,subevent
                           ,c1_record.vdate
                           ,c1_record.vtime
                           ,S_dci_name
                           ,S_dcm_name
                           ,S_dcm_subset
                           ,dcm_quesgrp
                           ,dcm_ques
                           ,xrepeat_sn
                           ,c1valuetext
                           ,c1_record.qualifying_value
                           ,c1_record.oc_study
                           ,tableid);
      dcm_ques    := 'LAB_DATA_CODE';
      c1valuetext := c1_record.test_component_id;
      Check_and_Set_Field (investigator
                           ,site
                           ,c1_record.oc_patient_pos
                           ,document_no
                           ,planned_event
                           ,subevent
                           ,c1_record.vdate
                           ,c1_record.vtime
                           ,S_dci_name
                           ,S_dcm_name
                           ,S_dcm_subset
                           ,dcm_quesgrp
                           ,dcm_ques
                           ,xrepeat_sn
                           ,c1valuetext
                           ,c1_record.qualifying_value
                           ,c1_record.oc_study
                           ,tableid);
      dcm_ques    := 'LAB_DATA_SOURCE';
      c1valuetext := c1_record.laboratory;
      Check_and_Set_Field (investigator
                           ,site
                           ,c1_record.oc_patient_pos
                           ,document_no
                           ,planned_event
                           ,subevent
                           ,c1_record.vdate
                           ,c1_record.vtime
                           ,S_dci_name
                           ,S_dcm_name
                           ,S_dcm_subset
                           ,dcm_quesgrp
                           ,dcm_ques
                           ,xrepeat_sn
                           ,c1valuetext
                           ,c1_record.qualifying_value
                           ,c1_record.oc_study
                           ,tableid);
      dcm_ques    := 'NORMAL_VALUES';
       c1valuetext := c1_record.normal_value;
       Check_and_Set_Field (investigator
                           ,site
                           ,c1_record.oc_patient_pos
                           ,document_no
                           ,planned_event
                           ,subevent
                           ,c1_record.vdate
                           ,c1_record.vtime
                           ,S_dci_name
                           ,S_dcm_name
                           ,S_dcm_subset
                           ,dcm_quesgrp
                           ,dcm_ques
                           ,xrepeat_sn
                           ,c1valuetext
                           ,c1_record.qualifying_value
                           ,c1_record.oc_study
                           ,tableid);
      dcm_ques    := 'LAB_PANEL';
      c1valuetext := c1_record.panel_name;
      Check_and_Set_Field (investigator
                           ,site
                           ,c1_record.oc_patient_pos
                           ,document_no
                           ,planned_event
                           ,subevent
                           ,c1_record.vdate
                           ,c1_record.vtime
                           ,S_dci_name
                           ,S_dcm_name
                           ,S_dcm_subset
                           ,dcm_quesgrp
                           ,dcm_ques
                           ,xrepeat_sn
                           ,c1valuetext
                           ,c1_record.qualifying_value
                           ,c1_record.oc_study
                           ,tableid);
  ENd; -- insert record
BEGIN
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('FINDREPEAT_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
   Else
      Log_Util.LogMessage('Lab Load Results Upd ("'||v_type||'") Starting');
   End If;
    -- update flags indicating patient processing
    last_oc_lab_panel    := '~';
    last_oc_lab_subset   := '~';
    last_oc_patient_pos  := '0';
    last_sample_datetime := '000000';
    last_study           := '~';
   OPEN c1;
   LOOP
      FETCH c1 INTO c1_record;
      EXIT WHEN c1%NOTFOUND;
      -- Get the DCI/DCM/Subset for this lab_panel
      Log_Util.LogMessage('LLRU - Looking up - '||
                          c1_Record.OC_STUDY||' / '||c1_Record.oc_patient_pos||' / '||
                          c1_Record.OC_LAB_PANEL||' / '||c1_Record.OC_LAB_SUBSET||' / '||
                          c1_Record.oc_lab_question||' / '||c1_Record.vdate||' / '||
                          c1_Record.vtime||'.');
      LoadFlag := TRUE;
      Log_Util.LogMessage('LLRU -       Find DCI, DCM, DCM Subset');
      SELECT distinct d.name, d.dcm_id, d.subset_name, dc.name
        into S_dcm_name, S_dcm_id, S_dcm_subset, S_dci_name
        FROM DCMS d,
             DCI_MODULES dm,
             DCIS dc,
             dci_book_pages bp,
             dci_books b
       WHERE d.name                 = c1_record.oc_lab_panel
         and d.subset_name          = c1_record.oc_lab_subset
         and d.clinical_study_id    = c1_record.study_id
         and d.dcm_subset_sn        = dm.dcm_subset_sn
         and d.dcm_id               = dm.dcm_id
         and dm.dci_id              = dc.dci_id
         and dc.dci_id              = bp.dci_id
         and b.dci_book_id          = bp.dci_book_id
         and dc.dci_status_code     = 'A'
         and b.DCI_BOOK_STATUS_CODE = 'A';
      Log_Util.LogMessage('LLRU -       Found. DCI = ['||S_Dci_Name||']; '||
                                              'DCM = ['||S_Dcm_Name||']; '||
                                              'DCM_Subset = ['||S_Dcm_Subset||'] ');
      Log_Util.LogMessage('LLRU -       Find Repeat_sn for question on Panel.');
      Begin
         SELECT distinct rp.repeat_sn
           INTO xrepeat_sn
           FROM dcms          d,
                received_dcms rd,
                dcm_questions dp,
                responses     rp
          WHERE d.DOMAIN            = c1_Record.OC_STUDY
            AND d.NAME              = c1_Record.OC_LAB_PANEL
            AND d.SUBSET_NAME       = c1_Record.OC_LAB_SUBSET
            and d.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
            AND d.dcm_id            = rd.dcm_id
            AND d.DCM_SUBSET_SN     = rd.DCM_SUBSET_SN
            AND d.dcm_layout_sn     = rd.DCM_LAYOUT_SN
            and rd.patient          = c1_Record.oc_patient_pos
            AND rd.DCM_DATE         = C1_Record.vdate
            AND rd.DCM_TIME         = c1_Record.Vtime
            AND dp.DCM_ID           = d.dcm_id
            AND dp.DCM_QUE_DCM_SUBSET_SN = d.DCM_SUBSET_SN
            AND dp.DCM_QUE_DCM_LAYOUT_SN = d.DCM_LAYOUT_SN
            AND dp.QUESTION_NAME         = 'LPARM'
            and rp.CLINICAL_STUDY_ID     = rd.CLINICAL_STUDY_ID
            AND rp.RECEIVED_DCM_ID       = rd.RECEIVED_DCM_ID
            AND rp.DCM_QUESTION_ID       = dp.DCM_QUESTION_ID
            AND rp.VALUE_TEXT            = c1_Record.OC_LAB_QUESTION
            and rp.END_TS                = to_date(3000000, 'J')
            and rd.END_TS                = to_date(3000000, 'J');
         Log_Util.LogMessage('LLRU -       Found.  Repeat_Sn = ['||to_char(xrepeat_sn)||']');
      Exception
         When No_Data_Found Then
         Begin
            Log_Util.LogMessage('LLRU -       Not Found, Checking Study Design.');
            SELECT distinct rd.repeat_sn
               INTO xrepeat_sn
               FROM dcm_ques_repeat_defaults rd, dcm_questions dq, dcms d
              WHERE d.dcm_id = S_dcm_id
                and d.subset_name = S_dcm_subset
                and d.dcm_id = dq.dcm_id
                and rd.dcm_subset_sn = dq.dcm_que_dcm_subset_sn  -- Added to ensure proper subset to repeat default
                and d.dcm_subset_sn = dq.dcm_que_dcm_subset_sn
                and dq.dcm_question_id = rd.dcm_question_id
                and dq.QUESTION_NAME = 'LPARM'
                and rd.default_value_text = c1_record.oc_lab_question;
            Log_Util.LogMessage('LLRU -       Found in Study Design. Repeat_Sn = ['||to_char(xrepeat_sn)||']');
            -- Found it in Design, but does it match current Repeat SN Question --
            Log_Util.LogMessage('LLRU -       Checking QUESTION Value.');
            Begin
               SELECT rp.VALUE_TEXT
                 INTO qname
                 FROM dcms          d,
                      received_dcms rd,
                      dcm_questions dp,
                      responses     rp
                WHERE d.DOMAIN            = c1_Record.OC_STUDY
                  AND d.NAME              = c1_Record.OC_LAB_PANEL
                  AND d.SUBSET_NAME       = c1_Record.OC_LAB_SUBSET
                  and d.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                  AND d.dcm_id            = rd.dcm_id
                  AND d.DCM_SUBSET_SN     = rd.DCM_SUBSET_SN
                  AND d.dcm_layout_sn     = rd.DCM_LAYOUT_SN
                  and rd.patient          = c1_Record.oc_patient_pos
                  AND rd.DCM_DATE         = C1_Record.vdate
                  AND rd.DCM_TIME         = c1_Record.Vtime
                  AND dp.DCM_ID           = d.dcm_id
                  AND dp.DCM_QUE_DCM_SUBSET_SN = d.DCM_SUBSET_SN
                  AND dp.DCM_QUE_DCM_LAYOUT_SN = d.DCM_LAYOUT_SN
                  AND dp.QUESTION_NAME         = 'LPARM'
                  and rp.CLINICAL_STUDY_ID     = rd.CLINICAL_STUDY_ID
                  AND rp.RECEIVED_DCM_ID       = rd.RECEIVED_DCM_ID
                  AND rp.DCM_QUESTION_ID       = dp.DCM_QUESTION_ID
                  AND rp.repeat_sn             = xrepeat_sn
                  and rp.END_TS                = to_date(3000000, 'J')
                  and rd.END_TS                = to_date(3000000, 'J');
               -- If the Question to load does not match the existing question, through and error.
               Update nci_labs
                  set load_flag = 'E',
                      Error_reason = 'Error - Wrong QUESTION (Repeat_SN '||to_char(xrepeat_sn)||' has Quesiton value of "'||
                                     qname||'" when expecting "'||C1_Record.OC_LAB_QUESTION||'".'
                where record_id = c1_Record.record_id
                  and qname <> C1_Record.OC_LAB_QUESTION;
               If qname <> C1_Record.OC_LAB_QUESTION then
                  LoadFlag := False;
                  Log_Util.LogMessage('LLRU -       Questions to load does not matcdh Question Loaded.');
               End If;
            Exception
               When No_Data_Found Then
                  Null;  -- Good, We can put the Update Record at this position
            End;
         Exception
            When No_Data_Found Then
            Begin
               Log_Util.LogMessage('LLRU -       Repeat_SN not found. Must be a non-repeat group.');
               SELECT max(rp.repeat_sn)
                 INTO xrepeat_sn
                 FROM dcms          d,
                      received_dcms rd,
                      dcm_questions dp,
                      responses     rp
                WHERE d.DOMAIN = c1_Record.OC_STUDY
                  AND d.NAME   = c1_Record.OC_LAB_PANEL
                  AND d.SUBSET_NAME = c1_Record.OC_LAB_SUBSET
                  and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
                  AND d.dcm_id=rd.dcm_id
                  AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
                  AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
                  and rd.patient = c1_Record.oc_patient_pos
                  AND rd.DCM_DATE= TO_CHAR(TO_DATE(c1_Record.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd')
                  AND rd.DCM_TIME= SUBSTR(c1_Record.SAMPLE_DATETIME,7)||'00'
                  AND dp.DCM_ID=d.dcm_id
                  AND dp.DCM_QUE_DCM_SUBSET_SN=d.DCM_SUBSET_SN
                  AND dp.DCM_QUE_DCM_LAYOUT_SN=d.DCM_LAYOUT_SN
                  AND dp.QUESTION_NAME='LPARM'
                  and rp.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                  AND rp.RECEIVED_DCM_ID=rd.RECEIVED_DCM_ID
                  AND rp.DCM_QUESTION_ID=dp.DCM_QUESTION_ID
                  --AND rp.VALUE_TEXT = c1_Record.OC_LAB_QUESTION
                  and Rp.END_TS = to_date(3000000, 'J')
                  and rd.END_TS = to_date(3000000, 'J');
               If (last_oc_lab_panel   = c1_record.oc_lab_panel and
                   last_oc_lab_subset  = c1_record.oc_lab_subset and
                   last_oc_patient_pos = c1_record.oc_patient_pos and
                   last_sample_datetime= c1_record.sample_datetime and
                   last_study          = c1_record.oc_study) Then
                  v_repeat_add := v_repeat_add + 1;
                  Log_Util.LogMessage('LLRU -      Adding one to v_repeat_add');
               Else
                  v_repeat_add :=  1;
                  Log_Util.LogMessage('LLRU -      Setting v_repeat_add = 1');
               End If;
               Log_Util.LogMessage('LLRU -      Adding v_repeat_add to repeat_sn');
               xrepeat_sn := nvl(xrepeat_sn,0) + v_repeat_add;
               If xrepeat_sn is null then
                  SELECT max(rp.repeat_sn)+1
                    INTO xrepeat_sn
                    FROM dcms          d,
                         received_dcms rd,
                         dcm_questions dp,
                         responses     rp
                   WHERE d.DOMAIN = c1_Record.OC_STUDY
                     AND d.NAME   = c1_Record.OC_LAB_PANEL
                     AND d.SUBSET_NAME = c1_Record.OC_LAB_SUBSET
                     and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
                     AND d.dcm_id=rd.dcm_id
                     AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
                     AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
                     and rd.patient = c1_Record.oc_patient_pos
                     AND rd.DCM_DATE= TO_CHAR(TO_DATE(c1_Record.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd')
                     AND rd.DCM_TIME= SUBSTR(c1_Record.SAMPLE_DATETIME,7)||'00'
                     AND dp.DCM_ID=d.dcm_id
                     AND dp.DCM_QUE_DCM_SUBSET_SN=d.DCM_SUBSET_SN
                     AND dp.DCM_QUE_DCM_LAYOUT_SN=d.DCM_LAYOUT_SN
                     AND dp.QUESTION_NAME='LPARM'
                     and rp.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                     AND rp.RECEIVED_DCM_ID=rd.RECEIVED_DCM_ID
                     AND rp.DCM_QUESTION_ID=dp.DCM_QUESTION_ID
                     --AND rp.VALUE_TEXT = c1_Record.OC_LAB_QUESTION
                     and Rp.END_TS = to_date(3000000, 'J')
                     and rd.END_TS = to_date(3000000, 'J');
                  Log_Util.LogMessage('LLRU -       Repeat_SN found = ['||to_char(xrepeat_sn)||']');
               End If;
            Exception
               When Others Then
                  Update nci_labs
                     set load_flag = 'E',
                         Error_reason = 'Max Repeat SN could not be found!'
                   where record_id = c1_Record.record_id;
               LoadFlag := False;
               Log_Util.LogMessage('LLRU -       Max Repeat_SN not Found for Non-Repeat Group.');
               Log_Util.LogMessage('LLRU -       Error Encountered: ' || SQLCODE);
               Log_Util.LogMessage('LLRU -       Error Message: ' || SQLERRM);
            End;
            When Others Then
               Update nci_labs
                  set load_flag = 'E',
                      Error_reason = 'Unexpected Error during Study Design REPEAT_SN find.'
                where record_id = c1_Record.record_id;
               LoadFlag := False;
               Log_Util.LogMessage('LLRU -       Repeat_SN not Found in  Study Design.');
               Log_Util.LogMessage('LLRU -       Error Encountered: ' || SQLCODE);
               Log_Util.LogMessage('LLRU -       Error Message: ' || SQLERRM);
         End;
         When Others Then
            Update nci_labs
               set load_flag = 'E',
                   Error_reason = 'Unexpected Error during REPEAT_SN find.'
             where record_id = c1_Record.record_id;
            LoadFlag := False;
            Log_Util.LogMessage('LLRU -       Repeat_SN not Found in Loaded Data.');
            Log_Util.LogMessage('LLRU -       Error Encountered: ' || SQLCODE);
            Log_Util.LogMessage('LLRU -       Error Message: ' || SQLERRM);
      End;
      If LoadFlag Then
         Log_Util.LogMessage('LLRU -       Find Event,SubEvent');
         Begin
            -- prc 06/06/06: added subevent_number retrieval
            SELECT distinct rd.subevent_number, CLIN_PLAN_EVE_NAME
              INTO subevent, planned_event
              FROM dcms          d,
                   received_dcms rd,
                   dcm_questions dp,
                   responses     rp
             WHERE d.DOMAIN            = c1_Record.OC_STUDY
               AND d.NAME              = c1_Record.OC_LAB_PANEL
               AND d.SUBSET_NAME       = c1_Record.OC_LAB_SUBSET
               and d.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
               AND d.dcm_id            = rd.dcm_id
               AND d.DCM_SUBSET_SN     = rd.DCM_SUBSET_SN
               AND d.dcm_layout_sn     = rd.DCM_LAYOUT_SN
               and rd.patient          = c1_Record.oc_patient_pos
               AND rd.DCM_DATE         = C1_Record.vdate
               AND rd.DCM_TIME         = c1_Record.Vtime
               AND dp.DCM_ID           = d.dcm_id
               AND dp.DCM_QUE_DCM_SUBSET_SN = d.DCM_SUBSET_SN
               AND dp.DCM_QUE_DCM_LAYOUT_SN = d.DCM_LAYOUT_SN
               AND dp.QUESTION_NAME         = 'LPARM'
               and rp.CLINICAL_STUDY_ID     = rd.CLINICAL_STUDY_ID
               AND rp.RECEIVED_DCM_ID       = rd.RECEIVED_DCM_ID
               AND rp.DCM_QUESTION_ID       = dp.DCM_QUESTION_ID
               --AND rp.VALUE_TEXT            = c1_Record.OC_LAB_QUESTION
               and rp.END_TS                = to_date(3000000, 'J')
               and rd.END_TS                = to_date(3000000, 'J');
            -- prc 06/06/06 :changed message.
            Log_Util.LogMessage('LLRU -       Found Event = ['||planned_event||']; '||' SubEvent = ['||subevent||']');
            -- Update the Event in NCI_LABS
            Update nci_labs
               set oc_lab_event = planned_event
             where record_id = c1_Record.record_id;
            Insert_record;
         Exception
            When No_Data_Found Then
               Log_Util.LogMessage('LLRU -       Event and SubEvent not found. Check for Soft-Delete.');
               Begin
                  SELECT distinct rd.subevent_number, CLIN_PLAN_EVE_NAME
                    INTO subevent, planned_event
                    FROM dcms          d,
                         received_dcms rd
                   WHERE d.DOMAIN            = c1_Record.OC_STUDY
                     AND d.NAME              = c1_Record.OC_LAB_PANEL
                     AND d.SUBSET_NAME       = c1_Record.OC_LAB_SUBSET
                     and d.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                     AND d.dcm_id            = rd.dcm_id
                     AND d.DCM_SUBSET_SN     = rd.DCM_SUBSET_SN
                     AND d.dcm_layout_sn     = rd.DCM_LAYOUT_SN
                     and rd.patient          = c1_Record.oc_patient_pos
                     AND rd.DCM_DATE         = C1_Record.vdate
                     AND rd.DCM_TIME         = c1_Record.Vtime
                     and rd.received_dci_id = (
                                            SELECT max(rd2.received_dci_id)
                                              FROM dcms          d2,
                                                   received_dcms rd2
                                             WHERE d2.DOMAIN = d.domain
                                               AND d2.NAME   = d.NAME
                                               AND d2.SUBSET_NAME = d.SUBSET_NAME
                                               and d2.CLINICAL_STUDY_ID =rd2.CLINICAL_STUDY_ID
                                               AND d2.dcm_id = rd2.dcm_id
                                               AND d2.DCM_SUBSET_SN = rd2.DCM_SUBSET_SN
                                               AND d2.dcm_layout_sn = rd2.DCM_LAYOUT_SN
                                               and rd2.patient = rd.patient
                                               and rd2.clin_plan_eve_name = rd.clin_plan_eve_name
                                               and rd2.subevent_number    = rd.subevent_number);
                  Log_Util.LogMessage('LLRU -       Soft Delete Found, Event = ['||planned_event||']; '||
                                      ' SubEvent = ['||subevent||']');
                  -- Update the Event in NCI_LABS
                  Update nci_labs
                     set oc_lab_event = planned_event
                   where record_id = c1_Record.record_id;
                  Insert_record;
               Exception
                  When No_Data_Found Then
                     Update nci_labs
                        set load_flag = 'E',
                            Error_reason = 'Update Record missing its Event and Subevent'
                      where record_id = c1_Record.record_id;
                     Log_Util.LogMessage('LLRU -       Event and SubEvent not Found for Update Record.');
                  When Others Then
                     Update nci_labs
                        set load_flag = 'E',
                            Error_reason = 'Unexpected Error during Event / Subevent find.'
                      where record_id = c1_Record.record_id;
                     Log_Util.LogMessage('LLRU -       Error Encountered: ' || SQLCODE);
                     Log_Util.LogMessage('LLRU -       Error Message: ' || SQLERRM);
               End;
            When Others Then
               Update nci_labs
                  set load_flag = 'E',
                      Error_reason = 'Unexpected Error during Event / Subevent find.'
                where record_id = c1_Record.record_id;
               Log_Util.LogMessage('LLRU -       Error Encountered: ' || SQLCODE);
               Log_Util.LogMessage('LLRU -       Error Message: ' || SQLERRM);
         End;
      Else
         Log_Util.LogMessage('LLRU -       Record Not Loaded due to error.' || SQLERRM);
      End If; --[LoadFlag = TRUE]
    -- store current values for use in matching additional lab results
    -- update flags indicating patient processing
    last_oc_lab_panel   := c1_record.oc_lab_panel;
    last_oc_lab_subset  := c1_record.oc_lab_subset;
    last_oc_patient_pos := c1_record.oc_patient_pos;
    last_sample_datetime:= c1_record.sample_datetime;
    last_study          := c1_record.oc_study;
  END LOOP;
  CLOSE c1;
END; -- load_lab_results
/


