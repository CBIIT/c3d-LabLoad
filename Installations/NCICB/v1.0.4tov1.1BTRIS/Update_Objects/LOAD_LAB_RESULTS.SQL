CREATE OR REPLACE PROCEDURE load_lab_results (v_Type in Varchar2, v_Study in Varchar2 Default '%') AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Unknown                                                               */
  /*       Date: Unknown                                                               */
  /*Description: (Original Description Missing)                                        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 07/15/03                                                                  */
  /*    Mod: 1) Found that date conversion was causing bad dates                       */
  /*         ie to_date('99','YY') = '2099'.  Replaced all 'YY' with 'RR'              */
  /*         2) Cleaned Code for Readability                                           */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 10/22/03                                                                  */
  /*    Mod: 1) Added active status to DCI/DCM lookup query.                           */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 04/08/04                                                                  */
  /*    Mod: 1) Removed section of code the marked Duplicates.  This is now done in the*/
  /*         Flag_Dup_Lab_Results procedure.                                           */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 08/19/04                                                                  */
  /*    Mod: 1) Added parameter to procedure so that NEW records can be run first, then*/
  /*         DUPLICATES can be run after.                                              */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  tableid         varchar2(20);
  investigator    varchar2(10);
  site            varchar2(10);
  planned_event   varchar2(40);
  S_dci_name      varchar2(50);
  S_dcm_id        number(10);
  S_dcm_name      varchar2(50);
  S_dcm_subset    varchar2(50);
  dcm_quesgrp     varchar2(50);
  dcm_ques        varchar2(50);
  study           varchar2(50);
  c1patient       varchar2(50);
  c1dci_date      varchar2(50);
  c1valuetext     varchar2(200);
  c1qual_value    varchar2(80);
  dci_time        varchar2(6);
  oc_panel        varchar2(20);
  oc_panel_subset varchar2(12);
  edate date;
  currpnt       varchar2(10);
  lastpnt       varchar2(10);
  laststudy     varchar2(50);
  lastvdate     varchar2(10);
  lastvtime     varchar2(6);
  first_patient char(1);
  subevent      number(2);
  document_no   varchar2(20);
  repeat_sn     number(4);
  no_repeat     number(4);
  ltf_name      varchar2(200);
  lre_name      varchar2(200);
  labcat_name   varchar2(200);
  currdate      varchar2(8);
  v_repeat_add  number(4) := 0;
  xc1patient     varchar2(50);
  xc1study       varchar2(50);
  xdocument_no   varchar2(20);
  xsubevent      number(2);
  xplanned_event varchar2(40);
  xc1dci_date    varchar2(50);
  xdci_time      varchar2(6);
  xdci_name      varchar2(50);
  xdcm_name      varchar2(50);
  xdcm_subset    varchar2(50);
  xtableid       varchar2(20);
  xqual_value    varchar2(80);
  last_oc_lab_panel    varchar2(20);
  last_oc_lab_subset   varchar2(12);
  last_oc_patient_pos  varchar2(12);
  last_sample_datetime varchar2(10);
  last_oc_lab_question varchar2(20);
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
       and s.study like nvl(v_Study,'%') -- prc 01/11/07: IOB
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
BEGIN
  If Log_Util.Log$LogName is null Then
     Log_Util.LogSetName('MISREPEAT_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
  End If;
  Log_Util.LogMessage('LLR - Lab Load Results Starting (Type = '||v_type||')');
  lastpnt       := 0;
  laststudy     := '~';
  subevent      := null;
  no_repeat     := 1;
  lastvdate     := '000000';
  first_patient := 'Y';
  repeat_sn     := 0;
  document_no   := null;
  investigator  := null;
  site          := null;
  OPEN c1;
  LOOP
    FETCH c1 INTO c1_record;
    EXIT WHEN c1%NOTFOUND;
    planned_event   := c1_record.oc_lab_event;
    c1patient       := c1_record.oc_patient_pos;
    c1dci_date      := c1_record.vdate;
    currpnt         := c1_record.patient_id;
    dci_time        := c1_record.vtime;
    oc_panel        := c1_record.oc_lab_panel;
    oc_panel_subset := c1_record.oc_lab_subset;
    study           := c1_record.oc_study;
    c1qual_value    := c1_record.qualifying_value;
    if (currpnt = lastpnt and study = laststudy) then
      if (c1dci_date = lastvdate) AND (dci_time = lastvtime) AND
         (oc_panel = last_oc_lab_panel) AND
         (oc_panel_subset = last_oc_lab_subset) then
        NULL;
      else
        --    subevent := subevent + 1;
        dcm_ques    := null;
        c1valuetext := null;
        insert_lab_data.insert_missing_responses(investigator
                                                ,site
                                                ,xc1patient
                                                ,xdocument_no
                                                ,xplanned_event
                                                ,xsubevent
                                                ,xc1dci_date
                                                ,xdci_time
                                                ,xdci_name
                                                ,xdcm_name
                                                ,xdcm_subset
                                                ,dcm_quesgrp
                                                ,dcm_ques
                                                ,no_repeat
                                                ,c1valuetext
                                                ,xqual_value   -- added for qualify_value
                                                ,xc1study
                                                ,xtableid);
        insert_lab_data.delete_repeats;
        subevent := null;
      end if;
    else
      --  subevent := 0;
      if first_patient = 'Y' then
        null;
      else
        -- since this is a new patient, reset the repeat_sn to the beginning
        repeat_sn := 1;
        dcm_ques    := null;
        c1valuetext := null;
        insert_lab_data.insert_missing_responses(investigator
                                                ,site
                                                ,xc1patient
                                                ,xdocument_no
                                                ,xplanned_event
                                                ,xsubevent
                                                ,xc1dci_date
                                                ,xdci_time
                                                ,xdci_name
                                                ,xdcm_name
                                                ,xdcm_subset
                                                ,dcm_quesgrp
                                                ,dcm_ques
                                                ,no_repeat
                                                ,c1valuetext
                                                ,xqual_value
                                                ,xc1study
                                                ,xtableid);
        insert_lab_data.delete_repeats;
        subevent := null;
      end if;
    end if;
    BEGIN
      Log_Util.LogMessage('LLR - Trying to find: ');
      Log_Util.LogMessage('      '||c1_Record.OC_STUDY||' / '||c1_Record.OC_LAB_PANEL||
                                 ' / '||c1_Record.OC_LAB_SUBSET||' / '||c1_Record.oc_patient_pos||
                                 ' / '||c1_Record.vdate||' / '||c1_Record.vtime||'.'||
                                 'Question ['||c1_Record.OC_LAB_QUESTION||']');
      -- Get the DCI/DCM/Subset for this lab_panel
      SELECT distinct d.name, d.dcm_id, d.subset_name, dc.name
        into S_dcm_name, S_dcm_id, S_dcm_subset, S_dci_name
        FROM DCMS d, DCI_MODULES dm, DCIS dc,
             dci_book_pages bp, dci_books b -- prc 04/01/2004:  Only look at 'Active' DCI Books
       WHERE d.name = c1_record.oc_lab_panel and
             d.subset_name = c1_record.oc_lab_subset and
             d.clinical_study_id = c1_record.study_id and
             d.dcm_subset_sn = dm.dcm_subset_sn and d.dcm_id = dm.dcm_id and
             dm.dci_id = dc.dci_id
         AND dc.dci_id = bp.dci_id
         AND b.dci_book_id = bp.dci_book_id
         AND dc.dci_status_code = 'A'  -- PRC 10/22/03: Added Active Status.
         and b.DCI_BOOK_STATUS_CODE = 'A'; -- prc 04/01/2004:  Only look at 'Active' DCI Books
    END;
    BEGIN
      -- Get the Repeat_Sn for the Question using results from above
      SELECT rd.repeat_sn
        INTO repeat_sn
        FROM dcm_ques_repeat_defaults rd, dcm_questions dq, dcms d
       WHERE d.dcm_id = S_dcm_id
         and d.subset_name = S_dcm_subset
         and d.dcm_id = dq.dcm_id
         and rd.dcm_subset_sn = dq.dcm_que_dcm_subset_sn  -- Added to ensure proper subset to repeat default
         and d.dcm_subset_sn = dq.dcm_que_dcm_subset_sn
         and dq.dcm_question_id = rd.dcm_question_id
         and dq.QUESTION_NAME = 'LPARM'
         and rd.default_value_text = c1_record.oc_lab_question;
      Log_Util.LogMessage('      Found GLIB Repeat Sn Question ['||c1_Record.OC_LAB_QUESTION||
                          '] "'||repeat_sn||'"@('||c1_record.oc_lab_event||')');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN -- Means, that question is on a non default_repeat dcm
         Begin
            -- prc 10/18/04 : Added subevent lookup
            -- prc 09/22/04 : See if this labtest has loaded already
            Log_Util.LogMessage('LLR - DEFAULT QUESTION REPEAT_SN NOT FOUND, Checking Responses...');
            Log_Util.LogMessage('LLR - DEFAULT QUESTION REPEAT_SN NOT FOUND, Checking for '||c1_Record.OC_LAB_QUESTION);
            SELECT max(rp.repeat_sn)
              INTO repeat_sn
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
               AND rp.VALUE_TEXT = c1_Record.OC_LAB_QUESTION
               and Rp.END_TS = to_date(3000000, 'J');
            If repeat_sn is null Then
            -- PRC 09/22/04 : Find the Greatest repeat seq for LabTest / Panel / Date
               Log_Util.LogMessage('LLR - RESPONSE REPEAT_SN NOT FOUND, Getting MAX Repeat_SN for: ');
               Log_Util.LogMessage('      '||c1_Record.OC_STUDY||' / '||c1_Record.OC_LAB_PANEL||
                                   ' / '||c1_Record.OC_LAB_SUBSET||' / '||c1_Record.oc_patient_pos||
                                   ' / '||c1_Record.vdate||' / '||c1_Record.vtime||'.');
               SELECT max(rp.repeat_sn)
                 INTO repeat_sn
                 FROM dcms          d,
                      received_dcms rd,
                      dcm_questions dp,
                      responses     rp
                WHERE d.DOMAIN = c1_Record.OC_STUDY
                  AND d.NAME   = c1_Record.OC_LAB_PANEL
                  AND d.SUBSET_NAME = c1_Record.OC_LAB_SUBSET
                  and d.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
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
                  and Rp.END_TS = to_date(3000000, 'J');
               If (last_oc_lab_panel  = c1_record.oc_lab_panel and
                   last_oc_lab_subset  = c1_record.oc_lab_subset and
                   last_oc_patient_pos = c1_record.oc_patient_pos and
                   last_sample_datetime= c1_record.sample_datetime and
                   laststudy           = c1_record.oc_study) Then
                  v_repeat_add := v_repeat_add + 1;
                  Log_Util.LogMessage('LLR - Adding one to v_repeat_add');
               Else
                  v_repeat_add :=  1;
                  Log_Util.LogMessage('LLR - Setting v_repeat_add = 1');
               End If;
               Log_Util.LogMessage('LLR - Adding v_repeat_add to repeat_sn');
               repeat_sn := nvl(repeat_sn,0) + v_repeat_add;
            End If;
         End;
    END;
    If v_type = 'S' Then
       -- Get the Subevent Number for the soft-deleted panel.
       SELECT distinct clin_plan_eve_name, subevent_number
         INTO planned_event, subevent
         FROM dcms          d,
              received_dcms rd
        WHERE d.DOMAIN = C1_Record.OC_STUDY
          AND d.NAME   = C1_Record.OC_LAB_PANEL
          AND d.SUBSET_NAME = C1_Record.OC_LAB_SUBSET
          and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
          AND d.dcm_id=rd.dcm_id
          AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
          AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
          and rd.patient = C1_Record.oc_patient_pos
          AND rd.DCM_DATE= C1_Record.vdate
          AND rd.DCM_TIME= C1_Record.vtime
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
       -- prc 06/06/06 :changed message.
       Log_Util.LogMessage('LLRU -       Found Event = ['||planned_event||']; '||' SubEvent = ['||subevent||']');
       -- Update the Event in NCI_LABS
       Update nci_labs
          set oc_lab_event = planned_event
        where record_id = c1_Record.record_id;
    Else
       -- This is a NEW record, subevent number not needed.
       SubEvent := Null;
    End If;
    dcm_quesgrp := 'LAB';
    dcm_ques    := 'LPARM';
    c1valuetext := c1_record.oc_lab_question;
    tableid     := c1_record.oc_lab_panel;
    insert_lab_data.insert_record(investigator
                                 ,site
                                 ,c1patient
                                 ,document_no
                                 ,planned_event
                                 ,subevent
                                 ,c1dci_date
                                 ,dci_time
                                 ,S_dci_name
                                 ,S_dcm_name
                                 ,S_dcm_subset
                                 ,dcm_quesgrp
                                 ,dcm_ques
                                 ,repeat_sn
                                 ,c1valuetext
                                 ,c1qual_value
                                 ,study
                                 ,tableid);
    dcm_ques    := 'LVALUE';
    c1valuetext := c1_record.result;
    insert_lab_data.insert_record(investigator
                                 ,site
                                 ,c1patient
                                 ,document_no
                                 ,planned_event
                                 ,subevent
                                 ,c1dci_date
                                 ,dci_time
                                 ,S_dci_name
                                 ,S_dcm_name
                                 ,S_dcm_subset
                                 ,dcm_quesgrp
                                 ,dcm_ques
                                 ,repeat_sn
                                 ,c1valuetext
                                 ,c1qual_value
                                 ,study
                                 ,tableid);
    dcm_ques    := 'LAB_UOM';
    c1valuetext := c1_record.unit;
    Check_and_Set_Field (investigator
                        ,site
                        ,c1patient
                        ,document_no
                        ,planned_event
                        ,subevent
                        ,c1dci_date
                        ,dci_time
                        ,S_dci_name
                        ,S_dcm_name
                        ,S_dcm_subset
                        ,dcm_quesgrp
                        ,dcm_ques
                        ,repeat_sn
                        ,c1valuetext
                        ,c1qual_value
                        ,study
                        ,tableid);
    dcm_ques    := 'LAB_DATA_CODE';
    c1valuetext := c1_record.test_component_id;
    Check_and_Set_Field (investigator
                        ,site
                        ,c1patient
                        ,document_no
                        ,planned_event
                        ,subevent
                        ,c1dci_date
                        ,dci_time
                        ,S_dci_name
                        ,S_dcm_name
                        ,S_dcm_subset
                        ,dcm_quesgrp
                        ,dcm_ques
                        ,repeat_sn
                        ,c1valuetext
                        ,c1qual_value
                        ,study
                        ,tableid);
    dcm_ques    := 'LAB_DATA_SOURCE';
    c1valuetext := c1_record.laboratory;
    Check_and_Set_Field (investigator
                        ,site
                        ,c1patient
                        ,document_no
                        ,planned_event
                        ,subevent
                        ,c1dci_date
                        ,dci_time
                        ,S_dci_name
                        ,S_dcm_name
                        ,S_dcm_subset
                        ,dcm_quesgrp
                        ,dcm_ques
                        ,repeat_sn
                        ,c1valuetext
                        ,c1qual_value
                        ,study
                        ,tableid);
    dcm_ques    := 'NORMAL_VALUES';
    c1valuetext := c1_record.normal_value;
    Check_and_Set_Field (investigator
                        ,site
                        ,c1patient
                        ,document_no
                        ,planned_event
                        ,subevent
                        ,c1dci_date
                        ,dci_time
                        ,S_dci_name
                        ,S_dcm_name
                        ,S_dcm_subset
                        ,dcm_quesgrp
                        ,dcm_ques
                        ,repeat_sn
                        ,c1valuetext
                        ,c1qual_value
                        ,study
                        ,tableid);
    dcm_ques    := 'LAB_PANEL';
    c1valuetext := c1_record.panel_name;
    Check_and_Set_Field (investigator
                        ,site
                        ,c1patient
                        ,document_no
                        ,planned_event
                        ,subevent
                        ,c1dci_date
                        ,dci_time
                        ,S_dci_name
                        ,S_dcm_name
                        ,S_dcm_subset
                        ,dcm_quesgrp
                        ,dcm_ques
                        ,repeat_sn
                        ,c1valuetext
                        ,c1qual_value
                        ,study
                        ,tableid);
    -- store repeat_sn for the LPARM record
    --Log_Util.LogMessage('IRS - repeat_sn = '||to_char(repeat_sn));
    insert_lab_data.save_repeat(repeat_sn);
    -- store current values for use with missing responses
    xc1patient     := c1patient;
    xc1study       := study;
    xdocument_no   := document_no;
    xsubevent      := subevent;
    xc1dci_date    := c1dci_date;
    xdci_time      := dci_time;
    xdci_name      := S_dci_name;
    xdcm_name      := S_dcm_name;
    xdcm_subset    := S_dcm_subset;
    xtableid       := tableid;
    xplanned_event := planned_event;
    xqual_value    := c1qual_value;
    -- store current values for use in matching additional lab results
    last_oc_lab_panel    := c1_record.oc_lab_panel;
    last_oc_lab_subset   := c1_record.oc_lab_subset;
    last_oc_patient_pos  := c1_record.oc_patient_pos;
    last_sample_datetime := c1_record.sample_datetime;
    last_oc_lab_question := c1_record.oc_lab_question;
    -- update flags indicating patient processing
    lastpnt       := c1_record.patient_id;
    laststudy     := c1_record.oc_study;
    lastvdate     := c1_record.vdate;
    lastvtime     := c1_record.vtime;
    first_patient := 'N';
    <<endrecord>>
    NULL;
  END LOOP;
  --process end of file with one more check of missing responses
  dcm_ques    := null;
  c1valuetext := null;
  Log_Util.LogMessage('IRS - Firing IMR');
  insert_lab_data.insert_missing_responses(investigator
                                          ,site
                                          ,c1patient
                                          ,document_no
                                          ,planned_event
                                          ,subevent
                                          ,c1dci_date
                                          ,dci_time
                                          ,S_dci_name
                                          ,S_dcm_name
                                          ,S_dcm_subset
                                          ,dcm_quesgrp
                                          ,dcm_ques
                                          ,no_repeat
                                          ,c1valuetext
                                          ,c1qual_value
                                          ,study
                                          ,tableid);
  insert_lab_data.delete_repeats;
  CLOSE c1;
END; -- load_lab_results
/


