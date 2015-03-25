CREATE OR REPLACE PACKAGE cdw_data_transfer_new AS

  -- Global Package Variables.

  MessageLogName     Varchar2(30) := Null; -- PRC 07/14/03
  MessageLogSequence Number := 1; -- PRC 07/14/03
  Labs_Count         Number; 

  -- Message (log) procedures PRC 07/14/03
  --Procedure MessageSetLog(LogName in Varchar2);
  --Procedure MessageToLog(InText in Varchar2);
  --Procedure MessageCleanLog(LogName in Varchar2);
  Procedure MessageLogPurge(LogName in Varchar2, LogDate in Date);
  
  Procedure Check_SubEvent_NUmbers;

  Procedure Get_Process_Load_Labs(Process_Type in Varchar2 default 'FULL');
  Function  pull_latest_labs Return Number;
  PROCEDURE prepare_cdw_labs;
  PROCEDURE process_lab_data;
  Procedure Process_Batch_Load;
  
  Procedure Reload_Error_Labs(E_Reason in Varchar2 Default '%');
  Procedure Recheck_Unmapped_Labs(P_Method in Varchar2 Default 'HELP'); -- prc 01/21/2004
  Procedure Update_After_Batch_Failure;
END cdw_data_transfer_new;
/

CREATE OR REPLACE PACKAGE BODY cdw_data_transfer_new AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad- Ekagra Software Technologies                          */
  /*       Date: 10/21/03                                                              */
  /*Description: Copied from original CDW_DATA_TRANSFER                                */
  /*             (Original Description Missing)                                        */
  /*             This process will get lab data from the external MIS (Sybase) system  */
  /*             and process the data prior to loading the lab data into Oracle        */
  /*             Clinical.  This process also prepares and execute the Batch Lab Load  */
  /*             process provided by Oracle Clinical.                                  */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*  PRC 01/21/2004 : Added Procedure Recheck_Unmapped_Labs.                          */
  /*  prc 04/01/2004 : Only look at 'Active' DCI Books                                 */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


 /* Procedure MessageSetLog(LogName in Varchar2) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/14/2003                                                            */
    /*Description: This procedure is used to set-up a new message log                    */
    /*                                                                                   */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 /*   v_Found   Number := 1;
    v_HoldLN  Varchar2(30);
    v_Counter Number := 0;

  Begin
    V_HoldLN := Upper(Substr(LogName, 1, 30));

    While v_Found <> 0 Loop
      select Count(*)
        Into v_Found
        from CDW_LAB_LOAD_LOG
       where LOGNAME like v_HoldLN;

      If v_Found > 0 Then
        v_HoldLN  := SubStr(MessageSetLog.LogName, 1, 27) ||
                     to_char(v_Counter, '099');
        v_Counter := v_Counter + 1;
      End if;
    End Loop;

    MessageLogName     := v_HoldLN;
    MessageLogSequence := 1;

    If LogName <> MessageLogName Then
      MessageToLog('Specified Log Name "' || LogName || '" changed to "' ||
                   MessageLogName || '".');
      Commit;
    End If;

  End; */

  /*Procedure MessageToLog(InText in Varchar2) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/14/2003                                                            */
    /*Description: This procedure is used to insert a message into the log table and     */
    /*             increment the message line counter.                                   */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 07/15/03                                                                  */
    /*    Mod: Added Check for MessageLogName being null.  Set to 'NONE SPECIFIED'       */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 /* Begin
    If MessageLogName is null Then
       MessageSetLog('NONE SPECIFIED');
    End If;

    Insert into CDW_LAB_LOAD_LOG
      (LOGNAME, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER)
    values
      (MessageLogName, MessageLogSequence, InText, Sysdate, User);

    MessageLogSequence := MessageLogSequence + 1;

  End; */

  /*Procedure MessageCleanLog(LogName in Varchar2) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/14/2003                                                            */
    /*Description: This procedure is used to insert a message into the log table and     */
    /*             increment the message line counter.                                   */
    /*                                                                                   */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  v_HoldLN Varchar2(30);

  Begin
    v_HoldLN := LogName;

    If v_HoldLN is null Then
      v_HoldLN := '%';
    End If;

    Begin
       Delete from CDW_LAB_LOAD_LOG where LOGNAME like v_HoldLN;

       Commit;
    Exception
       When Others Then
          MessageToLog('CLNLOG - Error during Clean Log:');        -- PRC 10/20/03: Added to check for errors here 
          MessageToLog('CLNLOG - Error Encountered: ' || SQLCODE); -- PRC 10/20/03: because the process once stopped
          MessageToLog('CLNLOG - Error Message: ' || SQLERRM);     -- PRC 10/20/03: at this section of code.
    End;
  End;*/

  Procedure MessageLogPurge(LogName in VarChar2, LogDate in Date) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 08/25/2003                                                            */
    /*Description: This procedure is used to identify those logs needing purged.  If     */
    /*             is null, '%' is used.  If LogDate is null, then SYSDATE-14 is used.   */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    v_HoldLN Varchar2(30);

  Begin
    v_HoldLN := LogName;

    For Cr1 in (select distinct LogName from Message_Logs 
                 where LogName like Nvl(v_HoldLn,'%')
                   and LogType = 'LABLOAD'
                   and LogDate <= nvl(MessageLogPurge.LogDate,Sysdate-14)) Loop

       Log_Util.LogClearLog(cr1.logName, 'LABLOAD');
    End Loop;
  End;


  Procedure Reload_Error_Labs(E_Reason in Varchar2 Default '%') is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/01/2003                                                            */
    /*Description: This procedure is used to identify labs that were not loaded due to   */
    /*             an error.  These labs are then reset back to 'NEW' (load_flag = 'N'), */
    /*             and that the process_labs procedure is executed.                      */
    /*             The procedure allows for specified errors to be examined viw the      */
    /*             E_Reason parameter.  If the parameter is not set, then all reasons    */
    /*             be targeted for reloading.                                            */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 07/16/03                                                                  */
    /*    Mod: Added Error Message Logging to help locate error location                 */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 02/05/04                                                                  */
    /*    Mod: Corrected Procedure.  It was not identifying and processing records from  */
    /*         the staging table NCI_LABS into BDL_TEMP_FILES.  It is now.               */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  Begin
    Log_Util.LogSetName('ERRORLABRELOAD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'ERRLABLOAD'); -- prc 07/16/03
    Log_Util.LogMessage('REL - Starting "RELOAD_ERROR_LABS" with Reason "'||E_Reason||'".'); -- prc 07/16/03

    Update NCI_LABS
       Set Load_flag    = 'N'
          ,Error_Reason = 'Reloaded due to: ' || Error_Reason
     where load_flag = 'E' and error_Reason like E_Reason;
    Commit;
    
    Log_Util.LogMessage('REL - '||to_char(SQL%RowCount)||' rows successfully set "Load_Flag=N" and "Error_Reason"');

    Log_Util.LogMessage('REL - About to call "PROCESS_LAB_DATA"'); -- prc 07/16/03
    process_lab_data;

    -- prc 02/05/04: Added section to CORRECTLY added records to BDL_TEMP_FILES
    select count(*)
      into labs_count
      from NCI_LABS
     where load_flag in ('N', 'R');
         
    if (labs_count > 0) then
       Log_Util.LogMessage('REL - '||to_char(labs_Count)||' records need processed in "NCI_LABS".');

       DELETE FROM BDL_TEMP_FILES;
       Log_Util.LogMessage('REL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to building.');
           
       Log_Util.LogMessage('REL - Executing "load_lab_results".');
       load_lab_results;
    Else
       Log_Util.LogMessage('GPLL - There are no records in "NCI_LABS" to process.');
    End If;
    -- prc 02/05/04: 
    
    Log_Util.LogMessage('REL - About to call "cdw_data_transfer_new.Process_Batch_Load"');
    cdw_data_transfer_new.Process_Batch_Load;
         
    -- execute the daily extract view package to update the processing date
    Log_Util.LogMessage('REL - About to call "ctvw_pkg.p_ct_data_dt"');
    ctvw_pkg.p_ct_data_dt;

    Log_Util.LogMessage('REL - Finished "RELOAD_ERROR_LABS"'); -- prc 07/16/03

  End; -- Reload_Error_Labs

  Procedure Recheck_Unmapped_Labs(P_Method in Varchar2 Default 'HELP') is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 01/21/2004                                                            */
    /*Description: This procedure is used to identify labs records that were  not loaded */
    /*             due to the 'Lab Test is unmapped' error.  These labs are examined to  */
    /*             determine if they are now mapped. There are 2 options for this        */
    /*             procedure.  MARK - Marks the records as 'NEW' and resets the field    */
    /*             ERROR_REASON.  These records will then wait for the next batch of Lab */
    /*             Loading to take place, and be included.  PROCESS - Performs the MARK  */
    /*             function, but will process the records immediately.                   */
    /*-----------------------------------------------------------------------------------*/
    /* Modification History:                                                             */
    /* PRC 01/21/2004: Christo Requested that the New Labs that were mapped be displayed.*/
    /*     I ran with this and added another paramter that allows a user to CHECK if any */
    /*     new labs can be mapped.                                                       */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 02/05/04                                                                  */
    /*    Mod: Corrected Procedure.  It was not identifying and processing records from  */
    /*         the staging table NCI_LABS into BDL_TEMP_FILES.  It is now.               */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  Begin
    If Log_Util.Log$LogName is null Then
       Log_Util.LogSetName('RECHCK_UNMAPPED_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
    End If;

    Log_Util.LogMessage('RCKUMP - Recheck Unmapped Labs Starting');
    Log_Util.LogMessage('RCKUMP - P_METHOD = '||P_METHOD);
  
    If Upper(P_Method) not in ('MARK','PROCESS','CHECK') Then
        Log_Util.LogMessage('RCKUMP -  Parameter '||P_METHOD||' is not a valid Parameter.');
        Log_Util.LogMessage('RCKUMP -  ');
        Log_Util.LogMessage('RCKUMP -  Usage:');
        Log_Util.LogMessage('RCKUMP -  ');
        Log_Util.LogMessage('RCKUMP -  cdw_data_transerfer_pkg_new.Recheck_Unmapped_Labs(''CHECK''|''MARK''|''PROCESS'')');
        Log_Util.LogMessage('RCKUMP -  ');
        Log_Util.LogMessage('RCKUMP -  CHECK   - Reports into the log file, those labs that are NEWLY mapped and');
        Log_Util.LogMessage('RCKUMP -            can be used in the Marking Process.');
        Log_Util.LogMessage('RCKUMP -  MARK    - Marks the records as "NEW" and resets the field ERROR_REASON.');
        Log_Util.LogMessage('RCKUMP -            These records will then wait for the next batch of Lab Loading');
        Log_Util.LogMessage('RCKUMP -  PROCESS - Performs the MARK function, but will then process the records');
        Log_Util.LogMessage('RCKUMP -            immediately.');
        Log_Util.LogMessage('RCKUMP - ');
    Else
       If Upper(P_Method) in ('MARK','PROCESS','CHECK') Then
          -- Report The LABS that will be found as having been mapped.
          For Xrec in (SELECT count(*) Rec_Count, M.OC_LAB_QUESTION, M.TEST_COMPONENT_ID, M.LAB_TEST 
                         FROM nci_lab_mapping m, 
                              nci_labs n 
                        WHERE load_flag = 'E' 
                          AND ERROR_REASON = 'Lab Test is unmapped' 
                          AND n.test_component_id = m.test_component_id 
                          AND n.laboratory = m.laboratory 
                          and m.oC_LAB_QUESTION is not null
                          and not exists (select TEST_COMPONENT_ID 
                                            from nci_lab_mapping q 
                                           where q.TEST_COMPONENT_ID = m.test_component_id 
                                           group by q.TEST_COMPONENT_ID 
                                          having count(*) > 1)
                        Group by M.OC_LAB_QUESTION, M.TEST_COMPONENT_ID, M.LAB_TEST ) Loop

             Log_Util.LogMessage('RCKUMP - CDW Lab: "'||Xrec.LAB_TEST||'" / "'||Xrec.TEST_COMPONENT_ID||'"'||
                                 '  Newly Mapped To: "'|| Xrec.OC_LAB_QUESTION ||'"  - Records Needing Update: '||
                                 to_char(Xrec.Rec_Count));

             If Upper(P_Method) in ('MARK','PROCESS') Then
                -- Mark the Records for re-processing
                Update NCI_LABS n
                   Set Load_flag    = 'N'
                      ,Error_Reason = 'Reloaded due to: ' || Error_Reason
                 where load_flag = 'E'
                   and error_Reason = 'Lab Test is unmapped'
                   and n.test_component_id = Xrec.TEST_COMPONENT_ID;
          
                Commit;
       
                Log_Util.LogMessage('RCKUMP - '||to_char(SQL%RowCount)||' rows successfully marked for reprocessing.');
          
             End If;
          End Loop;


       End If;
       If Upper(P_Method) in ('MARK') Then
          Log_Util.LogMessage('RCKUMP - '||'Records will be processed during next Lab Load Run.');
       End If;
       If Upper(P_Method) in ('PROCESS') Then
          Log_Util.LogMessage('RCKUMP - '||'Records will be processed NOW.');

          Log_Util.LogMessage('RCKUMP - About to call "PROCESS_LAB_DATA"');
          process_lab_data;

          -- prc 02/05/04: Added section to CORRECTLY added records to BDL_TEMP_FILES
          select count(*)
            into labs_count
            from NCI_LABS
           where load_flag in ('N', 'R');
               
          if (labs_count > 0) then
             Log_Util.LogMessage('REL - '||to_char(labs_Count)||' records need processed in "NCI_LABS".');

             DELETE FROM BDL_TEMP_FILES;
             Log_Util.LogMessage('REL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to building.');
                 
             Log_Util.LogMessage('REL - Executing "load_lab_results".');
             load_lab_results;
          Else
             Log_Util.LogMessage('GPLL - There are no records in "NCI_LABS" to process.');
          End If;
          -- prc 02/05/04: 

          Log_Util.LogMessage('RCKUMP - About to call "cdw_data_transfer_new.Process_Batch_Load"');
          cdw_data_transfer_new.Process_Batch_Load;
               
          -- execute the daily extract view package to update the processing date
          Log_Util.LogMessage('RCKUMP - About to call "ctvw_pkg.p_ct_data_dt"');
          ctvw_pkg.p_ct_data_dt;

          Log_Util.LogMessage('RCKUMP - Finished "RELOAD_ERROR_LABS"');
       End If;
     End If;

     Log_Util.LogMessage('RCKUMP - Recheck Unmapped Labs Finished.');

  End; -- Reload_Error_Labs

  Procedure Update_After_Batch_Failure is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/10/2003                                                            */
    /*Description: This procedure is used to identify labs that were recently loaded, but*/
    /*             the overall batch file load failed.  Labs that are set to 'NEW'       */
    /*             (load_flag = 'N'), are checked against recently entered responses.    */
    /*             If a match is found, then the NCI_LABS lab record is updated to 'C'.  */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 08/29/04                                                                  */
    /*    Mod: Replaced the "exists" clause with a more appropriate query.               */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  Begin
    update nci_labs n
       set load_flag    = 'C'
          ,load_date    = sysdate
          ,Error_reason = 'Batch Failed, but lab was loaded to OC'
     where load_flag = 'N' 
       and exists
            (SELECT n.PATIENT_ID, n.LABTEST_NAME, n.RESULT, n.sample_datetime,
                    rd.dcm_time,  rv.VALUE_TEXT
               FROM dcms          d, 
                    received_dcms rd, 
                    dcm_questions dp, 
                    dcm_questions dv, 
                    responses     rv, 
                    responses     rp
              WHERE d.DOMAIN=n.OC_STUDY
                AND d.NAME=n.OC_LAB_PANEL
                AND d.SUBSET_NAME=n.OC_LAB_SUBSET
                and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
                AND d.dcm_id=rd.dcm_id
                AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
                AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
                and rd.patient = n.oc_patient_pos
                AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddyyhh24mi'),'yyyymmdd')
                AND rd.DCM_TIME=SUBSTR(n.SAMPLE_DATETIME,7)||'00'
                AND dp.DCM_ID=d.dcm_id
                AND dp.DCM_QUE_DCM_SUBSET_SN=d.DCM_SUBSET_SN
                AND dp.DCM_QUE_DCM_LAYOUT_SN=d.DCM_LAYOUT_SN
                AND dp.QUESTION_NAME='LPARM'
                and rp.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                AND rp.RECEIVED_DCM_ID=rd.RECEIVED_DCM_ID
                AND rp.DCM_QUESTION_ID=dp.DCM_QUESTION_ID
                AND rp.VALUE_TEXT=n.OC_LAB_QUESTION
                AND dv.DCM_ID=d.dcm_id
                AND dv.DCM_QUE_DCM_SUBSET_SN=d.DCM_SUBSET_SN
                AND dv.DCM_QUE_DCM_LAYOUT_SN=d.DCM_LAYOUT_SN
                AND dv.QUESTION_NAME='LVALUE'
                and rv.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
                AND rv.RECEIVED_DCM_ID=rd.RECEIVED_DCM_ID
                AND rv.DCM_QUESTION_ID=dv.DCM_QUESTION_ID
                AND rv.VALUE_TEXT=n.RESULT
                AND rv.REPEAT_SN=rp.REPEAT_SN);
                
/* Replace the below sub-query with a more appropriate sub-query     
                  (select c.name
                  ,QUESTION_NAME
                  ,oc_lab_question
                  ,value_text
                  ,trunc(nvl(rd.modification_ts, received_dci_entry_ts)) modification_ts
                  ,nvl(rd.modified_by, rd.entered_by) modified_by
                  ,DATE_CREATED
              from responses         a
                  ,received_dcis     rd
                  ,received_dcms     b
                  ,dcms              c
                  ,dcm_questions     d
                  ,clinical_studies  f
                  ,patient_positions h
             where a.clinical_study_id = b.clinical_study_id and
                   b.received_dci_id = rd.received_dci_id and
                   a.received_dcm_id = b.received_dcm_id and
                   b.DCM_ID = c.dcm_id and b.DCM_SUBSET_SN = c.DCM_SUBSET_SN and
                   c.dcm_id = d.dcm_id and
                   c.DCM_SUBSET_SN = d.DCM_QUE_DCM_SUBSET_SN and
                   a.DCM_QUESTION_ID = d.DCM_QUESTION_ID and
                   a.DCM_QUESTION_GROUP_ID = d.DCM_QUESTION_GROUP_ID and
                   e.oc_study = f.STUDY and
                   f.clinical_study_id = a.clinical_study_id and
                   a.clinical_study_id = h.clinical_study_id and
                   rd.PATIENT_POSITION_ID = h.patient_position_id and
                   e.OC_PATIENT_POS = h.patient and e.OC_LAB_PANEL = c.name and
                   e.OC_LAB_QUESTION = a.VALUE_TEXT and
                   (nvl(rd.modified_by, rd.entered_by) = e.CREATED_BY) and
                   (trunc(nvl(rd.modification_ts, received_dci_entry_ts)) =
                   trunc(sysdate))); */

    Commit;

  End; -- Update_After_Batch_Failure is

  Procedure Check_SubEvent_NUmbers is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*       Date: 08/22/03                                                                  */
  /*Description: THis procedure checks each lab that is to be loaded, to ensure that it has*/
  /*             room to load within the DCM/Subevent notation.  Each DCM has a date/time  */
  /*             that relates to a SubEvent Number.  This procedure marks those labs that  */
  /*             would cause the subevent number to hit 95 or higher.  99 is the breaking  */
  /*             point of SubEvent within the System.                                      */
  /*  Modification History                                                                 */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                                  */
  /*   Date: 08/28/03                                                                      */
  /*    Mod: Changed patient,study,lab query to only return 1 row.  Also added When Others */
  /*         exception to catch unexpected errors.                                         */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                                  */
  /*   Date: 08/29/04                                                                      */
  /*    Mod: Altered SubEvent Checking to now after filling a visit, the next visit is     */
  /*         found, and the subevents start again.  This now allows for subevents for fill */
  /*         above 95, by going to the next event (visit).                                 */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
      v_errm          Varchar2(100);
      V_Max_SubeventN Number;
      v_dummy         varchar2(1);
      v_hold_event    varchar2(20);
      v_hold_dsn      number;
      d_hold_event    varchar2(20);
      
      Cursor Get_Event (in_study varchar2, in_Panel varchar2, in_Subset Varchar2) is
         select distinct CPE_NAME, display_sn
           from nci_study_ALL_dcms_events_vw C
          where c.oc_study = in_study
            and c.DCM_name = in_panel
            and C.Subset_name = in_subset
            order by display_sn;

   Begin
    If Log_Util.Log$LogName is null Then
       Log_Util.LogSetName('CHCKSUBEVNT_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
    End If;

    Log_Util.LogMessage('CHKSUBEVNT - Check SubEvent Numbers Starting');

      -- Primary Loop; Get all Distinct Study,patient,labs that will load.
      For Cr1 in 
         (select Distinct a.oc_study, b.clinical_study_id, oc_patient_pos, oc_lab_panel, oc_lab_subset
            from nci_labs a
                 ,clinical_studies b
           where b.study = a.OC_STUDY
             and a.load_flag IN ('N','R')) Loop

         Open Get_event(Cr1.clinical_study_id, Cr1.OC_Lab_Panel, Cr1.OC_Lab_Subset);

         v_max_subEventN := 100; 

         -- Secondary Loop; Get all distinct dates for the Study,Patient,Lab
         For Cr2 in (select distinct sample_datetime
                       from nci_labs a
                      where oc_study       = cr1.oc_study        
                        and oc_patient_pos = cr1.oc_patient_pos
                        and oc_lab_panel   = cr1.oc_lab_panel
                        and oc_lab_subset  = cr1.oc_lab_subset 
                        and load_flag in ('N', 'R')
                     ) Loop
         
            Begin
               -- Does this study,patient,lab exist in OC for this date
               Select CLIN_PLAN_EVE_NAME  
                 into d_hold_event
                 from received_dcms a,
                      dcms b
                where a.dcm_id = b.dcm_id
                  and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN         -- prc 04/08/04: Added Subset
                  and b.subset_name = cr1.oc_lab_subset         -- prc 04/08/04: Added Subset
                  and a.patient = Cr1.oc_patient_pos
                  and a.clinical_study_id = cr1.Clinical_study_id
                  and b.name = cr1.oc_lab_panel
                  and substr(dcm_date,5,2)||substr(dcm_date,7,2)||substr(dcm_date,3,2)||
                      substr(nvl(dcm_time,'000000'),1,4) = cr2.sample_datetime;
       
               UPDATE NCI_LABS N
                  SET OC_LAB_EVENT = d_hold_Event
                WHERE oc_study = cr1.oc_study
                  and oc_patient_pos = cr1.oc_patient_pos
                  and oc_lab_panel = cr1.oc_lab_panel
                  and oc_lab_subset= cr1.oc_lab_subset
                  and sample_datetime = cr2.sample_datetime
                  and load_flag in ('N','R');
       
       
            Exception
               When No_data_Found Then
                  -- This will cause a new event when above select has no data
                  If v_max_SubEventN < 95 Then

                     -- Increment the max Subevent incase there are more labs for patient
                     v_max_subEventN := v_Max_SubEventN + 1;

                     -- Set the Event in the Lab Record.
                     UPDATE NCI_LABS N
                        SET OC_LAB_EVENT = v_hold_Event
                      WHERE oc_study = cr1.oc_study
                        and oc_patient_pos = cr1.oc_patient_pos
                        and oc_lab_panel = cr1.oc_lab_panel
                        and oc_lab_subset= cr1.oc_lab_subset
                        and sample_datetime = cr2.sample_datetime
                        and load_flag in ('N','R');

                  Else

                     Loop
                           
                        Fetch Get_Event Into v_Hold_Event, v_hold_dsn;
                        If Get_Event%NOTFOUND Then
                        
                            Log_Util.LogMessage('CHKSUBEVNT - SubEvent error:"'||cr1.OC_STUDY||'/'||
                                                cr1.oc_patient_pos||'/'||cr1.oc_lab_panel||'/'||cr1.oc_lab_subset||
                                                '/'||cr2.sample_datetime||'.');
                                                
                           UPDATE NCI_LABS N
                              SET Load_Flag = 'E', Error_Reason = 'SubEvent Has Reached 95+.  Lab Not Loaded.',
                                  OC_LAB_EVENT = v_Hold_Event
                            WHERE oc_study = cr1.oc_study
                              and oc_patient_pos = cr1.oc_patient_pos
                              and oc_lab_panel = cr1.oc_lab_panel
                              and oc_lab_subset= cr1.oc_lab_subset
                              and sample_datetime = cr2.sample_datetime
                              and load_flag in ('N','R');

                        
                            Log_Util.LogMessage('CHKSUBEVNT - '||to_char(SQL%RowCount)||
                                                ' rows marked with "SubEvent" Error.');
                            Exit;
                        
                        End If;   
                           
                        -- Check the current maximum SubEvent Number
                        select nvl(max(subevent_number),0)
                          into v_max_SubEventN
                          from received_dcms a,
                               dcms b
                         where a.dcm_id = b.dcm_id
                           and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN            -- prc 04/08/04: Added Subset
                           and b.subset_name = cr1.oc_lab_subset            -- prc 04/08/04: Added Subset
                           and a.patient = cr1.oc_patient_pos
                           and a.clinical_study_id = cr1.Clinical_study_id
                           and b.name = cr1.oc_lab_panel
                           and a.CLIN_PLAN_EVE_NAME = v_Hold_Event;


                        Exit When v_max_subEventN < 95; 

                        Log_Util.LogMessage('CHKSUBEVNT - Bumped beyond Next Event('||v_hold_Event||')'||
                                      cr1.OC_STUDY||'/'||cr1.oc_patient_pos||'/'||
                                      cr1.oc_lab_panel||'/'||cr1.oc_lab_subset||'/'||cr2.sample_datetime||'.');

                     End Loop;

                     If v_max_SubEventN < 95 Then
                        -- Increment the max Subevent incase there are more labs for patient
                        v_max_subEventN := v_Max_SubEventN + 1;

                        -- Set the Event in the Lab Record.
                        UPDATE NCI_LABS N
                           SET OC_LAB_EVENT = v_hold_Event
                         WHERE oc_study = cr1.oc_study
                           and oc_patient_pos = cr1.oc_patient_pos
                           and oc_lab_panel = cr1.oc_lab_panel
                           and oc_lab_subset= cr1.oc_lab_subset
                           and sample_datetime = cr2.sample_datetime
                           and load_flag in ('N','R');

                        -- Log_Util.LogMessage('SUBEVNTCHCK - Bumped to Next Event('||v_hold_Event||')'||
                        --               cr1.OC_STUDY||'/'||cr1.oc_patient_pos||'/'||
                        --               cr1.oc_lab_panel||'/'||cr1.oc_lab_subset||'/'||cr2.sample_datetime||'.');

                     End If;
                  End If;
               When Others Then -- prc 08/28/03 added When others exception
                  Log_Util.LogMessage('CHKSUBEVNT - Error For"'||
                                       cr1.OC_STUDY||'('||CR1.clinical_study_id||')/'||cr1.oc_patient_pos||'/'||
                                       cr1.oc_lab_panel||'/'||cr1.oc_lab_subset||'/'||cr2.sample_datetime||'.');
                  Log_Util.LogMessage('Error Encountered: ' || SQLCODE);
                  Log_Util.LogMessage('Error Message: ' || SQLERRM);
                  v_errm := substr(sqlerrm,1,100);

                  UPDATE NCI_LABS N
                     SET LOAD_FLAG = 'E', ERROR_REASON = substr(v_errm,1,30)
                   WHERE oc_study = cr1.oc_study
                     and oc_patient_pos = cr1.oc_patient_pos
                     and oc_lab_panel = cr1.oc_lab_panel
                     and oc_lab_subset= cr1.oc_lab_subset
                     and sample_datetime = cr2.sample_datetime
                     and load_flag = 'N';

                  Log_Util.LogMessage('CHKSUBEVNT - '||to_char(SQL%RowCount)||' rows marked with "OTHER" Error.');
            End;
         End Loop;
         
         Close Get_Event;
         
      ENd Loop;
  
      Log_Util.LogMessage('CHKSUBEVNT - Check SubEvent Numbers Finished.');

   ENd; -- Check_SubEvent_NUmbers
   
  Function pull_latest_labs Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 08/28/03                                                                  */
  /*    Mod: Altered processing.  If primary select finds no candidates to execute, the*/
  /*         process stops.                                                            */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     v_rcount  number := 0;  -- prc 08/28/03

  BEGIN
     Log_Util.LogMessage('PLL - Beginning "PULL_LATEST_LABS".');

     Begin
        INSERT INTO cdw_lab_results
          (RESULT_ID
          ,PATIENT_ID
          ,RECORD_DATETIME
          ,TEST_ID
          ,TEST_CODE
          ,TEST_NAME
          ,TEST_UNIT
          ,ORDER_ID
          ,PARENT_TEST_ID
          ,ORDER_NUMBER
          ,ACCESSION
          ,TEXT_RESULT
          ,NUMERIC_RESULT
          ,HI_LOW_FLAG
          ,UPDATED_FLAG
          ,LOW_RANGE
          ,HIGH_RANGE
          ,REPORTED_DATETIME
          ,RECEIVED_DATETIME
          ,COLLECTED_DATETIME
          ,MASKED
          ,RANGE
          ,SPECIMEN_ID
          ,SPECIMEN_MODIFIER_ID
          ,QUALITATIVE_DICT_ID
          ,INSERTED_DATETIME
          ,UPDATE_DATETIME
          ,LOAD_FLAG
          ,LOAD_DATE)
          select substr("ResultId", 1, 15) Result_Id
                 ,MPI Patient_id
                 ,to_char("DateTime", 'mmddyy hh24:mi:ss') Record_DateTime
                 ,"TestId" Test_id
                 ,"TestCode" Test_Code
                 ,"TestName" test_name
                 ,"TestUnit" test_unit
                 ,substr("OrderId", 1, 15) Order_Id
                 ,"ParentTestId" parent_test_id
                 ,"OrderNumber" order_number
                 ,"Accession" accession
                 ,"TextResult" text_result
                 ,"NumericResult" numeric_result
                 ,"HiLowFlag" hi_low_flag
                 ,"UpdatedFlag" updated_flag
                 ,"LowRange" low_range
                 ,"HighRange" high_range
                 ,to_char("ReportedDate", 'mmddyy hh24:mi:ss') Reported_Datetime
                 ,to_char("ReceivedDate", 'mmddyy hh24:mi:ss') Received_Datetime
                 ,to_char("CollectedDate", 'mmddyy hh24:mi:ss') Collected_Datetime
                 ,"Masked" masked
                 ,"Range" range
                 ,"SpecimenId" specimen_id
                 ,"SpecimenModifierId" specimen_modifier_id
                 ,"QualitativeDictionaryId" qualitative_dict_id
                 ,to_char("InsertedDate", 'mmddyy hh24:mi:ss') Inserted_Datetime
                 ,to_char("UpdateDate", 'mmddyy hh24:mi:ss') update_datetime
                 ,'N'
                 ,sysdate
            from "vw_lab_results_current"@sybase
           where MPI in (select distinct REPLACE(PT_ID, '-', '')
                           from patient_id_ptid_vw
                          where NCI_INST_CD like '%NCI%'
                          minus  
                         select pt_id
                           FROM patient_id_ptid_vw
                          where decode(instr(translate(pt_id,
                                             '/ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                             'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'),
                                         'X'),0,'number','not_number') = 'not_number')
             AND ((to_date("InsertedDate", 'DD-MON-RR hh24:mi:ss') > -- PRC changed YY to RR
                 (select inserted_date from cdw_last_load) AND
                 MPI in (select distinct PATIENT_ID
                             FROM CDW_LAB_RESULTS
                            WHERE LOAD_FLAG = 'C')) OR
                 MPI NOT IN (select distinct PATIENT_ID
                                FROM CDW_LAB_RESULTS
                               WHERE LOAD_FLAG = 'C'));

     Exception
        When Others Then
           Log_Util.LogMessage('PLL - PRIMINS - Error Encountered: ' || SQLCODE);
           Log_Util.LogMessage('PLL - PRIMINS - Error Message: ' || SQLERRM);
            
     End;
     v_rcount := SQL%RowCount;

     Commit;

     Log_Util.LogMessage('PLL - '||to_char(v_rcount)||' rows inserted into "cdw_lab_results" from "vw_lab_results_current"@sybase.');
     Log_Util.LogMessage('PLL - Completed execution of Primary Select');

     Log_Util.LogMessage('PLL - Finished "PULL_LATEST_LABS"');
     
     Return v_Rcount;
     
  END pull_latest_labs;


  Procedure Get_Process_Load_Labs(Process_Type in Varchar2 default 'FULL') Is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* This procedure is used to control the processing of Lab Loading.  This      */
  /* procedure accepts one parameter.  The parameter control which process of    */
  /* the lab loading process should be executed.                                 */
  /* 'GET_PROC'   -  Get records from MIS (Sybase), process them upto the point  */
  /*                 of Batch Loading.  DO NOT BATCH LOAD.                       */
  /* ' BATCH'     -  Batch Load Records contained in NCI_LABS.                   */
  /*                 DO NOT GET RECORDS FROM MIS (Sybase)                        */
  /* 'FULL'       -  Get records from MIS (Sybase), process them upto the point  */
  /*                 of Batch Loading, perform Batch Loading.                    */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 

     v_MISCount      Number := 0;
     v_JobNumber     Number;
     v_Process_Type  Varchar2(20);
     
  Begin
     v_Process_Type := Substr(Upper(Process_Type),1,20);
     
     Log_Util.LogSetName('LABLOAD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
     Log_Util.LogMessage('GPLL - Beginning "GET_PROCESS_LOAD_LABS".');
     Log_Util.LogMessage('GPLL - Processing Type is "'||v_Process_Type||'".');
     Commit;

     If v_Process_Type in ('GET_PROC','FULL') Then
        
        -- Pull the MIS Labs from Sybase.
        Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_new.pull_latest_labs"');
        v_MISCount := cdw_data_transfer_new.Pull_Latest_labs;

        If v_MISCount > 0 Then 
  
           Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_new.prepare_cdw_labs"');
           cdw_data_transfer_new.prepare_cdw_labs;
  
           Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_new.process_lab_data"');
           cdw_data_transfer_new.process_lab_data;
           
           Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' lab records to Process.');
           
           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('N', 'R');
         
           if (labs_count > 0) then
              Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records need processed in "NCI_LABS".');

              DELETE FROM BDL_TEMP_FILES;
              Log_Util.LogMessage('GPLL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to building.');
           
              Log_Util.LogMessage('GPLL - Executing "load_lab_results".');
              load_lab_results;
           Else
              Log_Util.LogMessage('GPLL - There are no records in "NCI_LABS" to process.');
           End If;
  
        Else 
           Log_Util.LogMessage('GPLL - Primary Insert selected 0 candidate records.  Process Stopping.');
        End If;
     End If;
        
     If (v_Process_type ='BATCH' or (v_Process_type ='FULL' and v_MISCOunt > 0) ) Then
        
        Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_new.Process_Batch_Load"');
        cdw_data_transfer_new.Process_Batch_Load;
     
        -- execute the daily extract view package to update the processing date
        --Log_Util.LogMessage('Executing "ctvw_pkg.p_ct_data_dt"'); -- 01/23/04 Removed, now batch
        --ctvw_pkg.p_ct_data_dt;                                    -- 01/23/04 Removed, now batch

        Log_Util.LogMessage('GPLL - Sumbitting "ctvw_pkg.p_ct_data_dt"');  -- 01/23/04 now batch
        DBMS_JOB.Submit(v_jobnumber,'Begin ctvw_pkg.p_ct_data_dt; ENd;'); -- 01/23/04 now batch
        Log_Util.LogMessage('GPLL - Sumbitted "ctvw_pkg.p_ct_data_dt" Job Number='||v_jobnumber); -- 01/23/04 now batch
        
     End If;
     
     If v_Process_Type not in ('GET_PROC','BATCH','FULL') Then
        Log_Util.LogMessage('GPLL - Invalid Processing type.  Choose "GET_PROC", "BATCH", "FULL"');     
     End If;  

     Log_Util.LogMessage('GPLL - Finished "GET_PROCESS_LOAD_LABS".');

     Commit;
     
  End;

  PROCEDURE prepare_cdw_labs IS
  BEGIN
    DECLARE

      curr_pt           number(10);
      last_pt           number(10);
      lab_count         number(10);
      oc_pt             varchar2(10);
      oc_study_dom      varchar2(15);
      check_max         char(1);
      prestudy_lab_date date;
      pt_enrollment_dt  date;

      CURSOR c1 is
        SELECT PATIENT_ID
              ,RESULT_ID
              ,SUBSTR(COLLECTED_DATETIME, 1, 6) ||
               SUBSTR(COLLECTED_DATETIME, 8, 2) ||
               SUBSTR(COLLECTED_DATETIME, 11, 2) COLLECT_DATETIME
              ,to_date(SUBSTR(COLLECTED_DATETIME, 1, 6), 'MMDDRR') COLLECTION_DATE -- PRC Change YY to RR
              ,TEST_ID
              ,TEST_CODE
              ,'CDW' LABORATORY
              ,TEST_NAME
              ,TEXT_RESULT
              ,TEST_UNIT
              ,RANGE
              ,SYSDATE
          FROM CDW_LAB_RESULTS
         WHERE LOAD_FLAG = 'N'
         ORDER BY patient_id, collected_datetime, test_id, test_name;

      c1_record c1%ROWTYPE;

    BEGIN
       last_pt   := null;
       curr_pt   := null;
       lab_count := 0;

       Log_Util.LogMessage('PCL - Beginning "PREPARE_CDW_LABS".');
       
       insert into NCI_LABS
                  (PATIENT_ID
                   ,CDW_RESULT_ID
                   ,SAMPLE_DATETIME
                   ,TEST_COMPONENT_ID
                   ,TEST_CODE
                   ,LABORATORY
                   ,LABTEST_NAME
                   ,RESULT
                   ,UNIT
                   ,NORMAL_VALUE
                   ,RECEIVED_DATE)
            SELECT PATIENT_ID
                   ,RESULT_ID
                   ,SUBSTR(COLLECTED_DATETIME, 1, 6) ||
                    SUBSTR(COLLECTED_DATETIME, 8, 2) ||
                    SUBSTR(COLLECTED_DATETIME, 11, 2) COLLECT_DATETIME
                   ,TEST_ID
                   ,TEST_CODE
                   ,'CDW' LABORATORY
                   ,TEST_NAME
                   ,TEXT_RESULT
                   ,TEST_UNIT
                   ,RANGE
                   ,SYSDATE
              FROM CDW_LAB_RESULTS
             WHERE LOAD_FLAG = 'N';
        
        Log_Util.LogMessage(to_char(SQL%RowCount)||' records inserted into "NCI_LABS" from "CDW_LAB_RESULTS".');
        
       /*
       OPEN c1;
       LOOP
          FETCH c1 INTO c1_record;
          
          EXIT WHEN c1%NOTFOUND;

          BEGIN
             curr_pt := c1_record.patient_id;
             IF curr_pt = last_pt then
                goto check_lab_dates;
             end if;

             BEGIN

                dbms_output.put_line('Processing Records for patient: ' ||  c1_record.patient_id);
                Log_Util.LogMessage('PCL - Processing Records for patient: ' ||c1_record.patient_id);

                SELECT distinct pt, study
                  into oc_pt, oc_study_dom
                  from patient_id_ptid_vw
                 where to_char(c1_record.patient_id) = REPLACE(PT_ID, '-', '') 
                   and NCI_INST_CD like '%NCI%';
  
             EXCEPTION
                when others then
                   dbms_output.put_line('Error Encountered: ' || SQLCODE);
                   dbms_output.put_line('Error Message: ' || SQLERRM);
                   Log_Util.LogMessage('PCL - PTID - Error Encountered: ' || SQLCODE);
                   Log_Util.LogMessage('PCL - PTID - Error Message: ' || SQLERRM);
             END;

             -- Retrieve patient enrollment date for the study
             BEGIN
                SELECT to_date(SUBSTR(R1.VALUE_TEXT, 1, 8), 'YYYYMMDD')
                  into pt_enrollment_dt
                  FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
                 WHERE D.NAME = 'ENROLLMENT' AND D.DCM_STATUS_CODE = 'A' AND
                       D.DOMAIN = oc_study_dom AND D.DCM_ID = RD.DCM_ID AND
                       D.DCM_ID = Q.DCM_ID AND
                       R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID AND
                       R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID AND
                       R1.END_TS = RD.END_TS AND     -- prc 08/25/03 This should limit it to latest record.
                       R1.END_TS = to_date(3000000, 'J') AND
                       Q.QUESTION_NAME = 'REG_DT' AND RD.PATIENT = oc_pt;

             EXCEPTION
                when others then
                   dbms_output.put_line('Error Encountered: ' || SQLCODE);
                   dbms_output.put_line('Error Message: ' || SQLERRM);
                   Log_Util.LogMessage('PCL - RPED - Error Encountered: ' || SQLCODE);
                   Log_Util.LogMessage('PCL - RPED - Error Message: ' || SQLERRM);
             END;

             -- Determine if there's a Prestudy Lab Date defined for this patient
             BEGIN
                SELECT to_date(SUBSTR(R1.VALUE_TEXT, 1, 8), 'YYYYMMDD')
                  into prestudy_lab_date
                  FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
                 WHERE D.NAME = 'ENROLLMENT' AND D.DCM_STATUS_CODE = 'A' AND
                       D.DOMAIN = oc_study_dom AND D.DCM_ID = RD.DCM_ID AND
                       D.DCM_ID = Q.DCM_ID AND
                       R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID AND
                       R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID AND
                       R1.END_TS = RD.END_TS AND     -- prc 08/26/03 Missed this one the first time through
                       R1.END_TS = to_date(3000000, 'J') AND
                       Q.QUESTION_NAME = 'PRESTUDY_LAB_DATE' AND
                       RD.PATIENT = oc_pt;

             EXCEPTION
                WHEN NO_DATA_FOUND then
                   --  dbms_output.put_line('No match found for prestudy lab date.');
                   --  no prestudy date found, so use the original study registration date
                   Log_Util.LogMessage('PCL - no prestudy date found, using the original study registration date.');
                   prestudy_lab_date := pt_enrollment_dt;
             END;
             dbms_output.put_line('Found lab start date:  ' || prestudy_lab_date);
             Log_Util.LogMessage('PCL - Patient: ' ||c1_record.patient_id||' - Found lab start date: ' || prestudy_lab_date);

             <<check_lab_dates>>
             Log_Util.LogMessage('PCL - Patient: ' ||c1_record.patient_id||' ** CheckLabDates: ');
          
             IF c1_record.COLLECTION_DATE < prestudy_lab_date then
                Log_Util.LogMessage('PCL - Record rejected: '  || c1_record.collection_date || ' to lab qual date: ' || prestudy_lab_date);

                update cdw_lab_results
                   set load_flag = 'E'
                 where result_id = c1_record.RESULT_ID;
             else 
                Log_Util.LogMessage('PCL - Record inserted into NCI Labs.');

                insert into NCI_LABS
                  (PATIENT_ID
                  ,CDW_RESULT_ID
                  ,SAMPLE_DATETIME
                  ,TEST_COMPONENT_ID
                  ,TEST_CODE
                  ,LABORATORY
                  ,LABTEST_NAME
                  ,RESULT
                  ,UNIT
                  ,NORMAL_VALUE
                  ,RECEIVED_DATE)
                values
                  (c1_record.PATIENT_ID
                  ,c1_record.RESULT_ID
                  ,c1_record.COLLECT_DATETIME
                  ,c1_record.TEST_ID
                  ,c1_record.TEST_CODE
                  ,c1_record.LABORATORY
                  ,c1_record.TEST_NAME
                  ,c1_record.TEXT_RESULT
                  ,c1_record.TEST_UNIT
                  ,c1_record.RANGE
                  ,c1_record.SYSDATE);
             --end if;

             last_pt := c1_record.patient_id;
          --END;

       END LOOP;
       CLOSE c1;
       */
       -- dbms_output.put_line('End of Loop Reached.');

       BEGIN

        begin
          DELETE FROM CDW_LAB_RESULTS WHERE LOAD_FLAG = 'E';
          Log_Util.LogMessage(to_char(SQL%RowCount)||' ERROR rows deleted from "CDW_LAB_RESULTS".');
                    
        EXCEPTION
          WHEN NO_DATA_FOUND then
            null;
          when others then
            dbms_output.put_line('Error Encountered: ' || SQLCODE);
            dbms_output.put_line('Error Message: ' || SQLERRM);
            Log_Util.LogMessage('PCL - DELCDW - Error Encountered: ' || SQLCODE);
            Log_Util.LogMessage('PCL - DELCDW - Error Message: ' || SQLERRM);
        end;

        begin
          select count(*)
            into lab_count
            from cdw_lab_results
           where load_flag = 'N';
        EXCEPTION
          WHEN NO_DATA_FOUND then
            null;
          when others then
            dbms_output.put_line('Error Encountered: ' || SQLCODE);
            dbms_output.put_line('Error Message: ' || SQLERRM);
            Log_Util.LogMessage('PCL - CNTCDW - Error Encountered: ' || SQLCODE);
            Log_Util.LogMessage('PCL - CNTCDW - Error Message: ' || SQLERRM);
        end;

        begin
          check_max := 'Y';
          select 'N'
            into check_max
            from CDW_LAB_RESULTS
          having max(to_date(inserted_datetime, 'MMDDRR hh24:MI:SS')) -- PRC 07/01/03 Changed from YY to RR
                     <= (SELECT INSERTED_DATE FROM CDW_LAST_LOAD);
        EXCEPTION
          WHEN NO_DATA_FOUND then
            null;
          when others then
            dbms_output.put_line('Error Encountered: ' || SQLCODE);
            dbms_output.put_line('Error Message: ' || SQLERRM);
            Log_Util.LogMessage('PCL - CHKMAX - Error Encountered: ' || SQLCODE);
            Log_Util.LogMessage('PCL - CHKMAX - Error Message: ' || SQLERRM);
        end;

        begin

           if (lab_count > 0 and check_max = 'Y') then

              UPDATE CDW_LAST_LOAD
                 SET INSERTED_DATE = (SELECT max(to_date(inserted_datetime
                                                      ,'MMDDRR hh24:MI:SS')) -- PRC 07/01/03 Changed from YY to RR
                                        FROM CDW_LAB_RESULTS
                                       WHERE LOAD_FLAG = 'N');
              Log_Util.LogMessage('PCL - Updated CDW_LAST_LOAD(INSERTED_DATE).');

           end if;
        end;

        begin
           UPDATE CDW_LAB_RESULTS
              SET LOAD_FLAG = 'U'
            WHERE LOAD_FLAG = 'N' AND UPDATED_FLAG = '1';

           Log_Util.LogMessage('PCL - '||to_char(SQL%RowCount)||' CDW_LAB_RESULTS records updated LOAD_FLAG to "U".');

        EXCEPTION
           WHEN NO_DATA_FOUND then
              null;
           when others then
              dbms_output.put_line('Error Encountered: ' || SQLCODE);
              dbms_output.put_line('Error Message: ' || SQLERRM);
              Log_Util.LogMessage('PCL - SETLDU - Error Encountered: ' || SQLCODE);
              Log_Util.LogMessage('PCL - SETLDU - Error Message: ' || SQLERRM);
        end;

        begin
           UPDATE CDW_LAB_RESULTS
              set load_flag = 'C'
            WHERE LOAD_FLAG IN ('U', 'N');

           Log_Util.LogMessage('PCL - '||to_char(SQL%RowCount)||' CDW_LAB_RESULTS records updated LOAD_FLAG to "C".');

        EXCEPTION
           WHEN NO_DATA_FOUND then
             null;
           when others then
             dbms_output.put_line('Error Encountered: ' || SQLCODE);
             dbms_output.put_line('Error Message: ' || SQLERRM);
             Log_Util.LogMessage('PCL - SETLDC - Error Encountered: ' || SQLCODE);
             Log_Util.LogMessage('PCL - SETLDC - Error Message: ' || SQLERRM);
        end;

        COMMIT;

      END;
    END;
    Log_Util.LogMessage('PCL - Finishing "PREPARE_CDW_LABS".');

  END prepare_cdw_labs;

  PROCEDURE process_lab_data IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* This section is used to process records in NCI_LABS.  Records are marked    */
  /* with the appropriate values for patient and study as well as marked with an */
  /* error flag when they don't meet each of the individual tests below.         */
  /* The types of errors include:                                                */
  /*    Patient found on more than one study                                     */
  /*    Patient not on-study                                                     */
  /*    Etc.                                                                     */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     
     CURSOR c1 is
        SELECT PATIENT_ID
              ,CDW_RESULT_ID
              ,SAMPLE_DATETIME
              ,TEST_COMPONENT_ID
              ,TEST_CODE
              ,LABORATORY
              ,LABTEST_NAME
              ,RESULT
              ,UNIT
              ,NORMAL_VALUE
              ,RECEIVED_DATE
          FROM NCI_LABS
         WHERE LOAD_FLAG = 'N'
         ORDER BY patient_id
                 ,sample_datetime
                 ,test_component_id
                 ,labtest_name;

      c1_record c1%ROWTYPE;

      T_Counter   Number := 0;
      U_Counter   Number := 0;
      I_Counter   Number := 0;
      crnt_ptid   nci_labs.Patient_id%type;
      crnt_Study  nci_labs.OC_Study%type;
      crnt_OFF_OffSet_Days Number := 0;
      pt_enrollment_dt  Date;
      OffStudy_Date     Date;
      Prestudy_Lab_Date Date;
      dummy       varchar2(1); 

    BEGIN
       Log_Util.LogMessage('PLD - Beginning "PROCESS_LAB_DATA".');

       -- Set error condition for patient found on more than one study
       /* NOT NEEDED. FIXED BELOW
        update nci_labs
          set LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Patient on more than one study'
        WHERE LOAD_FLAG IN ('N', 'R') AND EXISTS
        (select count(*), T.pt_id
                 from patient_id_ptid_vw T, CLINICAL_STUDIES S
                WHERE REPLACE(T.PT_ID, '-', '') = nci_labs.PATIENT_ID and
                      T.NCI_INST_CD like '%NCI%' and T.STUDY = S.STUDY
                GROUP BY T.pt_id
               HAVING count(*) > 1);

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Patient on more than one study".');
       */
       -- Set error condition for patient found on study more thant once
       /*update nci_labs
          set LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Patient in same Study more than once'
        WHERE LOAD_FLAG IN ('N', 'R') 
          and Patient_id in 
        (select Replace(T.pt_id,'-','')
                 from patient_id_ptid_vw T, CLINICAL_STUDIES S
                WHERE T.NCI_INST_CD like '%NCI%' and T.STUDY = S.STUDY
                GROUP BY T.pt_id, T.STUDY
               HAVING count(*) > 1);

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Patient in same Study more than once".');
       */
       -- Set patient position ids and study
       update nci_labs
          set (oc_patient_pos, oc_study) = (select DISTINCT T.pt, S.Study
                                              from patient_id_ptid_vw T
                                                  ,CLINICAL_STUDIES   S
                                             WHERE REPLACE(T.PT_ID, '-', '') = nci_labs.PATIENT_ID and
                                                   T.NCI_INST_CD like '%NCI%' and
                                                   T.STUDY = S.STUDY 
                                               and pt_id not in (select nvl(pt_id,'~')
                                                                   from patient_id_ptid_vw T, CLINICAL_STUDIES S
                                                                  WHERE T.NCI_INST_CD like '%NCI%' and T.STUDY = S.STUDY
                                                                  GROUP BY T.pt_id, T.STUDY    
                                                                 HAVING count(*) > 1)
                                               and pt_id not in (select nvl(pt_id,'~')
                                                                   FROM patient_id_ptid_vw
                                                                  where decode(instr(translate(pt_id,
                                                                          '/ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                                                          'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'),
                                                                        'X'),0,'number','not_number') = 'not_number'                                                                                               
                                                                        )
                                               and rownum = 1    )
        WHERE LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully set "oc_patient_pos" and "oc_study"');

       -- Generate additional lab records for patient on more than one study.or on same study more than once.
       Insert into NCI_LABS 
                          (RECORD_ID, PATIENT_ID, SAMPLE_DATETIME, TEST_COMPONENT_ID,
                           LABORATORY, LABTEST_NAME, LAB_GRADE, RESULT,
                           UNIT, NORMAL_VALUE, PANEL_NAME, PATIENT_NAME,
                           COMMENTS, OC_LAB_PANEL, OC_LAB_QUESTION, OC_LAB_EVENT,
                           OC_PATIENT_POS, LOAD_DATE, LOAD_FLAG, RECEIVED_DATE,
                           DATE_CREATED, DATE_MODIFIED, CREATED_BY, MODIFIED_BY,
                           TEST_CODE, CDW_RESULT_ID, OC_STUDY, ERROR_REASON,
                           OC_LAB_SUBSET)
                     select NULL RECORD_ID
                            ,PATIENT_ID
                            ,SAMPLE_DATETIME
                            ,TEST_COMPONENT_ID
                            ,LABORATORY
                            ,LABTEST_NAME
                            ,LAB_GRADE
                            ,RESULT
                            ,UNIT
                            ,NORMAL_VALUE
                            ,PANEL_NAME
                            ,PATIENT_NAME
                            ,COMMENTS
                            ,NULL OC_LAB_PANEL
                            ,NULL OC_LAB_QUESTION
                            ,NULL OC_LAB_EVENT
                            ,T.PT
                            ,NULL LOAD_DATE
                            ,'N' LOAD_FLAG
                            ,RECEIVED_DATE
                            ,NULL DATE_CREATED
                            ,NULL DATE_MODIFIED
                            ,NULL CREATED_BY
                            ,NULL MODIFIED_BY
                            ,TEST_CODE
                            ,CDW_RESULT_ID
                            ,T.STUDY
                            ,NULL ERROR_REASON
                            ,NULL OC_LAB_SUBSET
                       from patient_id_ptid_vw T,
                            nci_labs b
                      WHERE REPLACE(T.PT_ID, '-') = b.PATIENT_ID
                        and T.NCI_INST_CD like '%NCI%'
                        and b.cdw_result_id is not null
                     minus
                     select NULL RECORD_ID
                            ,PATIENT_ID
                            ,SAMPLE_DATETIME
                            ,TEST_COMPONENT_ID
                            ,LABORATORY
                            ,LABTEST_NAME
                            ,LAB_GRADE
                            ,RESULT
                            ,UNIT
                            ,NORMAL_VALUE
                            ,PANEL_NAME
                            ,PATIENT_NAME
                            ,COMMENTS
                            ,NULL OC_LAB_PANEL
                            ,NULL OC_LAB_QUESTION
                            ,NULL OC_LAB_EVENT
                            ,OC_PATIENT_POS
                            ,NULL LOAD_DATE
                            ,'N' LOAD_FLAG
                            ,RECEIVED_DATE
                            ,NULL DATE_CREATED
                            ,NULL DATE_MODIFIED
                            ,NULL CREATED_BY
                            ,NULL MODIFIED_BY
                            ,TEST_CODE
                            ,CDW_RESULT_ID
                            ,OC_STUDY
                            ,NULL ERROR_REASON
                            ,NULL OC_LAB_SUBSET
                       from nci_labs b;
   
       
       Log_Util.LogMessage('PLD - Generated additional '||to_char(SQL%RowCount)||
                           ' lab records for patients on more than one study, or on same study more than once.');
        
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 04/13/04: Moved Section to Here (After Insert of "On More Than One Study"     */
       /* PRC 04/07/04: Added Section                                                       */
       /* Data Contraint Section.  Remove Records for Studies that have stopped loading labs*/
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       
       -- Mark Records as Rejected where the study is flagged to stop loading
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', 
              ERROR_REASON = 'Study is no longer loading labs. (NCI_LAB_LOAD_CTL.STOP_LAB_LOAD_FLAG=''Y'')'
        WHERE LOAD_FLAG IN ('N', 'R')
          AND OC_STUDY IN (select OC_STUDY from NCI_LAB_LOAD_CTL
                            where STOP_LAB_LOAD_FLAG = 'Y');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Study is no longer loading labs"');
       
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 01/21/04: Added Section                                                     */
       /* Data Contraint Section.  Remove Rcords for Bad Type, Length, etc                */
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       
       -- Mark Records as Rejected where Normal Value > 30;
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'NORMAL_VALUE to Long (> 30)'
        WHERE Length(NORMAL_VALUE) > 30 AND LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "NORMAL_VALUE to Long (> 30)"');

       -- Ensure each record has a patient_position_id
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Patient not on-study'
        WHERE OC_PATIENT_POS IS NULL AND LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Patient not on-study"');


       /* DATE CHECKS HERE 
          1) Collection date has to be > nvl(Prestudy Date, enrollment_date)
          2) Collection Date has to be less then nvl(offstudy date (+30), sysdate) */
       
       crnt_ptid := '~';
       crnt_Study:= '~';
       U_Counter := 0; -- Count Bad PreStudy
       I_Counter := 0; -- Count Bad Off Study
       For I_Rec in (select distinct Patient_id, OC_Study, OC_Patient_Pos 
                       from nci_labs a 
                      where load_flag IN ('N', 'R')
                      order by OC_Study, Patient_ID) LOOP
          BEGIN
       
             dbms_output.put_line('Processing Records for Study/patient: ' || I_Rec.OC_Study ||' / '||I_REc.patient_id);
             Log_Util.LogMessage('PCL - Processing Records for Study/patient: ' || I_Rec.OC_Study ||' / '||I_REc.patient_id);

             -- PRC 04/07/04: New Off Study OffSet Date Section
             If crnt_Study <> I_Rec.OC_Study Then
             Log_Util.LogMessage('PCL - Study Changed, Get OFF STUDY OffSet Days for Study: ' || I_Rec.OC_Study);
             Begin
                -- Get the study specific OFF STUDY OFFSET AMOUNT
                Select OFF_STUDY_OFFSET_DAYS 
                  into crnt_Off_Offset_Days
                  from NCI_LAB_LOAD_CTL
                 where OC_STUDY = I_Rec.OC_STUDY;
             Exception 
                When NO_DATA_FOUND Then
                   Begin
                      -- Get the DEFAULT OFF STUDY OFFSET AMOUNT for all studies
                      Select OFF_STUDY_OFFSET_DAYS 
                        into crnt_Off_Offset_Days
                        from NCI_LAB_LOAD_CTL
                       where OC_STUDY = 'ALL';
                   Exception
                      When NO_DATA_FOUND Then
                         crnt_OFF_OffSet_Days := 30;
                   End;
             End;
             Log_Util.LogMessage('PCL - OFF STUDY OffSet Days for Study: ' || I_Rec.OC_Study||
                                 ' is '||to_char(crnt_OFF_OffSet_Days));
             End If;                                                                        
           
             -- Retrieve patient enrollment date for the study
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 04/28/04: Changed Queries, added more join conditions, to speed the query   */
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
             SELECT to_date(SUBSTR(R1.VALUE_TEXT, 1, 8), 'YYYYMMDD')
               into pt_enrollment_dt
               FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
              WHERE D.NAME = 'ENROLLMENT' AND D.DCM_STATUS_CODE = 'A' AND
                    D.DOMAIN = I_Rec.OC_Study AND 
                    RD.CLINICAL_STUDY_ID = d.CLINICAL_STUDY_ID and  --prc 04/28/2004: Speed it
                    D.DCM_ID = RD.DCM_ID AND
                    D.DCM_ID = Q.DCM_ID AND
                    q.dcm_que_dcm_subset_sn = d.dcm_subset_sn and   --prc 04/28/2004: Speed it
                    q.dcm_que_dcm_layout_sn = d.dcm_layout_sn and   --prc 04/28/2004: Speed it
                    R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID and --prc 04/28/2004: Speed it                    
                    R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID AND
                    R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID AND
                    R1.END_TS = RD.END_TS AND     -- prc 08/25/03 This should limit it to latest record.
                    R1.END_TS = to_date(3000000, 'J') AND
                    Q.QUESTION_NAME = 'REG_DT' AND RD.PATIENT = I_Rec.oc_patient_pos;
            
          EXCEPTION
             when others then
                dbms_output.put_line('Error Encountered: ' || SQLCODE);
                dbms_output.put_line('Error Message: ' || SQLERRM);
                Log_Util.LogMessage('PCL - RPED - Error Encountered: ' || SQLCODE);
                Log_Util.LogMessage('PCL - RPED - Error Message: ' || SQLERRM);
          END;
                
                -- Determine if there's a Prestudy Lab Date defined for this patient
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 04/28/04: Changed Queries, added more join conditions, to speed the query   */
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
          BEGIN
             SELECT to_date(SUBSTR(R1.VALUE_TEXT, 1, 8), 'YYYYMMDD')
               into prestudy_lab_date
               FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
              WHERE D.NAME = 'ENROLLMENT' AND 
                    D.DCM_STATUS_CODE = 'A' AND
                    RD.CLINICAL_STUDY_ID = d.CLINICAL_STUDY_ID and  --prc 04/28/2004: Speed it
                    D.DOMAIN = I_Rec.OC_Study AND 
                    D.DCM_ID = RD.DCM_ID AND
                    D.DCM_ID = Q.DCM_ID AND
                    q.dcm_que_dcm_subset_sn = d.dcm_subset_sn and   --prc 04/28/2004: Speed it
                    q.dcm_que_dcm_layout_sn = d.dcm_layout_sn and   --prc 04/28/2004: Speed it
                    R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID and --prc 04/28/2004: Speed it                    
                    R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID AND
                    R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID AND
                    R1.END_TS = RD.END_TS AND     -- prc 08/26/03 Missed this one the first time through
                    R1.END_TS = to_date(3000000, 'J') AND
                    Q.QUESTION_NAME = 'PRESTUDY_LAB_DATE' AND
                    RD.PATIENT = i_Rec.oc_patient_pos;
           
          EXCEPTION
             WHEN NO_DATA_FOUND then
                --  dbms_output.put_line('No match found for prestudy lab date.');
                --  no prestudy date found, so use the original study registration date
                Log_Util.LogMessage('PCL - no prestudy date found, using the original study registration date.');
                prestudy_lab_date := pt_enrollment_dt;
          END;
          
          BEGIN
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 04/28/04: Changed Queries, added more join conditions, to speed the query   */
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
             SELECT to_date(SUBSTR(R1.VALUE_TEXT, 1, 8), 'YYYYMMDD')
               into offstudy_date
               FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
              WHERE D.NAME = 'OFF STUDY SUMM' AND 
                    D.DCM_STATUS_CODE = 'A' AND
                    RD.CLINICAL_STUDY_ID = d.CLINICAL_STUDY_ID and  --prc 04/28/2004: Speed it
                    D.DOMAIN = I_Rec.OC_Study AND 
                    RD.DCM_ID = D.DCM_ID AND                    
                    D.DCM_ID = Q.DCM_ID AND
                    q.dcm_que_dcm_subset_sn = d.dcm_subset_sn and   --prc 04/28/2004: Speed it
                    q.dcm_que_dcm_layout_sn = d.dcm_layout_sn and   --prc 04/28/2004: Speed it
                    R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID and --prc 04/28/2004: Speed it                    
                    R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID AND
                    R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID AND
                    R1.END_TS = RD.END_TS AND     -- prc 08/26/03 Missed this one the first time through
                    R1.END_TS = to_date(3000000, 'J') AND
                    Q.QUESTION_NAME = 'OFF_STDY_DT' AND
                    RD.PATIENT = i_Rec.oc_patient_pos;
           
          EXCEPTION
             WHEN NO_DATA_FOUND then
                --  no OFF Study Date, so use the end of time.
                Log_Util.LogMessage('PCL - no Off Study Date Found, using end of time.');
                OffStudy_date := to_date(3000000, 'J');
          END;
    
          -- Mark Lab Records as Errors, where Lab Sample Date is Less Than PresStudy Date.
          update nci_labs
             set load_flag = 'E',
                 Error_Reason = 'Lab Sample Date is less than PreStudy Lab Date'
           where to_date(substr(SAMPLE_DATETIME,1,6), 'mmddRR') < prestudy_lab_date
             and load_flag in ('N', 'R')
             and Patient_id = I_Rec.Patient_id
             and OC_Study   = I_rec.OC_Study;

          U_Counter := U_Counter + SQL%RowCount;
          Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                              ' records rejected because Lab Sample Date is less than PreStudy Lab Date (' || prestudy_lab_date||')');
          
          -- Mark Lab Records as Errors, where Lab Sample Date is more than 30 days after Study Date
          update nci_labs
             set load_flag = 'E',
                 Error_Reason = 'Lab Sample Date is more than 30 days after Off Study Date'
           where to_date(substr(SAMPLE_DATETIME,1,6), 'mmddRR') > OffStudy_Date + crnt_OFF_OffSet_Days --prc 04/07/04
             and load_flag in ('N', 'R')
             and Patient_id = I_Rec.Patient_id
             and OC_Study   = I_rec.OC_Study;
           
          I_Counter := I_Counter + SQL%RowCount;
          Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                              ' records rejected because Lab Sample Date is more than 30 days after Off Study Date(' || prestudy_lab_date||')');
          
       End loop;   
       Log_Util.LogMessage('PLD - '||to_char(U_Counter)||' rows marked with Error for "Lab Collection Date is less than PreStudy Lab Date"');
       Log_Util.LogMessage('PLD - '||to_char(I_Counter)||' rows marked with Error for "Lab Collection Date is more than 30 days after Off Study Date"');

       -- Set error condition for a lab defined to be in more than one place (either DCM or Visit) in a study.
       /* -- This section re-written for better performance...see below (PRC 12/11/03)
       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Lab found in more than one DCM/Visit'
        WHERE load_flag in ('N', 'R') and EXISTS
        (SELECT v.DEFAULT_VALUE_TEXT
                 FROM nci_lab_mapping   m
                     ,ctdev.duplicate_lab_mappings v
                WHERE M.test_component_id = N.test_component_id AND
                      M.laboratory = N.laboratory AND
                      V.STUDY = N.OC_STUDY AND
                      V.DEFAULT_VALUE_TEXT = M.OC_LAB_QUESTION);
       */
       I_Counter := 0;       
       
       For Dup_Lab in (SELECT V.STUDY, M.test_component_id,
                              M.laboratory, V.DEFAULT_VALUE_TEXT
                         FROM nci_lab_mapping   m
                             ,ctdev.duplicate_lab_mappings v
                        WHERE V.DEFAULT_VALUE_TEXT = M.OC_LAB_QUESTION) Loop
       
           Update NCI_LABS N
              SET LOAD_FLAG    = 'E'
                 ,ERROR_REASON = 'Lab found in more than one DCM/Visit'
            WHERE load_flag in ('N', 'R')
              and N.test_component_id = Dup_lab.test_component_id
              and N.laboratory        = Dup_Lab.Laboratory
              and N.OC_Study          = Dup_Lab.Study;
       
          I_Counter := I_Counter + SQL%RowCount;
          Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                              ' rows updated for error "Lab found in more than one DCM/Visit" '||
                              'Study/Test Component ID/Laboratory - '||
                              Dup_Lab.STUDY||'/'||Dup_Lab.test_component_id||'/'||Dup_Lab.laboratory);
       End Loop;
               
       Log_Util.LogMessage('PLD - '||I_Counter||' TOTAL rows updated for error "Lab found in more than one DCM/Visit"');

       -- Update oc_lab_question
       -- PRC 07/02/03:  There may be more than one oc_question per test_component_id
       UPDATE NCI_LABS N
          SET (OC_LAB_QUESTION) = (SELECT DISTINCT M.OC_LAB_QUESTION
                                     FROM nci_lab_mapping m
                                    WHERE n.test_component_id =
                                          m.test_component_id AND
                                          n.laboratory = m.laboratory and
                                          not exists
                                    (select TEST_COMPONENT_ID
                                             from nci_lab_mapping q
                                            where q.TEST_COMPONENT_ID =
                                                  m.test_component_id
                                            group by q.TEST_COMPONENT_ID
                                           having count(*) > 1))
        WHERE load_flag in ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_QUESTION".');

       -- Set error for test_component_id have 2 questions
       -- PRC 07/02/03:  There may be more than one oc_question per test_component_id
       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Lab Test Component ID (' || test_component_id ||
                             ') is double-mapped'
        WHERE load_flag in ('N', 'R') and exists
        (select TEST_COMPONENT_ID
                 from nci_lab_mapping q
                where q.TEST_COMPONENT_ID = n.test_component_id
                group by q.TEST_COMPONENT_ID
               having count(*) > 1);

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test Component ID ( xxx ) is double-mapped".');

       -- Determine the DCM, Subset and Clinical Planned Event for each mapped lab result
       UPDATE NCI_LABS N
             SET (OC_LAB_PANEL, OC_LAB_EVENT, OC_LAB_SUBSET) = 
                          (SELECT dcm_name, cpe_name, subset_name
                               FROM nci_study_dcms_events_vw B,
                                    clinical_studies cs
                              WHERE cs.clinical_study_id = B.oc_study 
                                and question_name = 'LPARM'
                                and cs.study = n.oc_study
                                and b.oc_lab_question = n.oc_lab_question
                                and oc_lab_question is not null
                                and display_sn = (select min(display_sn)
                                                    from nci_study_dcms_events_vw a
                                                   where a.oc_study = b.oc_study
                                                     and a.dcm_name = b.dcm_NAME
                                                     and a.subset_name = b.subset_name
                                                     and a.question_name = b.question_name
                                                     and a.repeat_sn = b.repeat_sn
                                                     and a.oc_lab_question = b.oc_lab_question))
                          WHERE load_flag in ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_PANEL", "OC_LAB_EVENT", "OC_LAB_SUBSET".');

       UPDATE NCI_LABS
          SET OC_LAB_PANEL  = 'LAB_ALL'
             ,OC_LAB_EVENT  = 'OTHER LABS'
             ,OC_LAB_SUBSET = 'LABA'
        WHERE oc_lab_panel is null AND oc_lab_subset is null AND
              oc_lab_question is not null AND result is not null AND
              load_flag in ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_PANEL", "OC_LAB_EVENT", "OC_LAB_SUBSET"'||
                    ' with LAB_ALL, OTHER LABS and LABA.');

       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* -- Determine the DCM, Question and Clinical Planned Event for each eligible lab result
       /* UPDATE NCI_LABS N
       /* SET (    OC_LAB_PANEL
       /*  , OC_LAB_QUESTION
       /*  , OC_LAB_EVENT
       /*  , OC_LAB_SUBSET)  =
       /*  (SELECT DISTINCT
       /*    v.dcm_name
       /*  ,     v.oc_lab_question
       /*  ,     v.cpe_name
       /*  , v.subset_name
       /*  FROM  clinical_studies s
       /*  ,   nci_lab_mapping m
       /*  ,   nci_study_dcms_vw  v
       /*  WHERE  n.oc_study = s.study
       /*  AND   n.test_component_id = m.test_component_id
       /*  AND   n.laboratory = m.laboratory
       /*  AND   V.QUESTION_NAME = 'LPARM'
       /*  AND   V.OC_STUDY = S.CLINICAL_STUDY_ID
       /*  AND   V.OC_LAB_QUESTION = M.OC_LAB_QUESTION)
       /*WHERE load_flag in ('N','R');
       /*
       /*UPDATE NCI_LABS
       /*SET OC_LAB_PANEL = 'LAB_ALL', OC_LAB_EVENT = 'OTHER LABS', OC_LAB_SUBSET='LABA'
       /*WHERE     oc_lab_panel is null
       /*AND   oc_lab_subset is null
       /*AND   oc_lab_question is not null
       /*AND   result is not null
       /*AND   load_flag in ('N','R');
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

       -- Check for Reject Records and specify Error Message

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Test is unmapped'
        WHERE OC_LAB_QUESTION IS NULL AND LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test is unmapped".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Test is invalid'
        WHERE UPPER(LABTEST_NAME) IN
              (SELECT UPPER(LABTEST_NAME) FROM NCI_INVALID_LABTESTS) AND
              LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test is invalid".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Result is null'
        WHERE RESULT IS NULL AND LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Result is null".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Result is invalid'
        WHERE UPPER(RESULT) IN
              (SELECT UPPER(RESULT_VALUE) FROM NCI_INVALID_RESULTS) AND
              LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Result is invalid".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Sample date is invalid'
        WHERE to_number(substr(sample_datetime, 7, 2)) > 23 AND
              LOAD_FLAG IN ('N', 'R');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Sample date is invalid".');

       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Invalid OC question used in mapping'
        WHERE LOAD_FLAG IN ('N', 'R') AND OC_LAB_QUESTION IS NOT NULL AND
              OC_LAB_PANEL != 'LAB_ALL' AND
              oc_lab_panel || ',' || oc_lab_question not in
              (SELECT DISTINCT V.DCM_NAME || ',' || V.OC_LAB_QUESTION
                 FROM CLINICAL_STUDIES S, NCI_STUDY_DCMS_VW V
                WHERE N.OC_STUDY = S.STUDY AND
                      S.CLINICAL_STUDY_ID = V.OC_STUDY AND
                      V.QUESTION_NAME = 'LPARM' AND
                      V.SUBSET_NAME = N.OC_LAB_SUBSET AND
                      V.DCM_NAME = N.OC_LAB_PANEL);

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Invalid OC question used in mapping".');

       -- PRC 09/17/2003: Added this error check when new study caused this error.
       -- prc 04/01/2004: Added DCI Books and Book Pages. Only look at 'Active' DCI Books
       -- prc 04/05/2004: Okay, Only mark records where there are 2 DIFFERENT DCI Names that can be
       --                 associated to the Study/DCM/DCM_Subset. (Which is done in load_lab_results)
       UPDATE NCI_LABS N 
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Lab Panel and Subset have Multiple DCIs'
        WHERE LOAD_FLAG IN ('N', 'R') 
          AND exists (SELECT count(distinct dc.name), d.name, d.dcm_id, d.subset_name -- prc 04/05/2004 : Count Distinct DCI NAME
                        FROM DCMS d, DCI_MODULES dm, DCIS dc, CLINICAL_STUDIES S, 
                             dci_book_pages bp, dci_books b -- prc 04/01/2004:  Only look at 'Active' DCI Books
                       WHERE s.Study = n.oc_study
                         and d.name = n.oc_lab_panel
                         and d.subset_name = n.oc_lab_subset
                         and d.clinical_study_id = s.clinical_study_id
                         and d.dcm_subset_sn = dm.dcm_subset_sn and d.dcm_id = dm.dcm_id
                         and dm.dci_id = dc.dci_id
                         AND dc.dci_id = bp.dci_id
                         AND b.dci_book_id = bp.dci_book_id
                         and dc.dci_status_code = 'A'     -- prc 10/20/2003:  Only look at 'Active' DCIs
                         and b.DCI_BOOK_STATUS_CODE = 'A' -- prc 04/01/2004:  Only look at 'Active' DCI Books
                       Group by d.name, d.dcm_id, d.subset_name -- prc 04/05/2004 : Count Distinct DCI NAME
                      Having count(distinct dc.name) > 1); -- prc 04/05/2004 : Count Distinct DCI NAME

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Panel and Subset have Multiple DCIs".');

       -- PRC 10/20/2003: Added this error check when a DCI module is requiring Time to be collected.
       UPDATE NCI_LABS N 
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'DCI requires time'
        WHERE LOAD_FLAG IN ('N', 'R') 
          AND exists (SELECT d.name, d.dcm_id, d.subset_name, dc.name
                        FROM DCMS d, DCI_MODULES dm, DCIS dc, CLINICAL_STUDIES S
                       WHERE s.Study = n.oc_study
                         and d.name = n.oc_lab_panel
                         and d.subset_name = n.oc_lab_subset
                         and d.clinical_study_id = s.clinical_study_id
                         and d.dcm_subset_sn = dm.dcm_subset_sn and d.dcm_id = dm.dcm_id
                         and dm.dci_id = dc.dci_id
                         and dc.dci_status_code = 'A' 
                         and dc.COLLECT_TIME_FLAG = 'Y' -- prc 10/20/2003:  Only look at DCIs requiring TIME collection
                      );

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "DCI requires time".');

       -- Identify duplicate records
       Log_Util.LogMessage('PLD - Executing "insert_lab_data.identify_duplicate_records".');
       insert_lab_data.identify_duplicate_records;
       Log_Util.LogMessage('PLD - Finished  "insert_lab_data.identify_duplicate_records".');

       -- validate the unit of measure
       UPDATE NCI_LABS N
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Invalid Unit of Measure'
        WHERE LOAD_FLAG IN ('N', 'R') AND N.UNIT IS NOT NULL AND
              N.UNIT != ' ' AND NOT EXISTS
        (SELECT U.VALUE
                 FROM NCI_UOMS U
                WHERE UPPER(N.UNIT) = UPPER(U.VALUE)
               UNION
                 SELECT U.PREFERRED
                   FROM NCI_UOM_MAPPING U
                  WHERE UPPER(N.UNIT) = UPPER(U.SOURCE)
               );

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Invalid Unit of Measure".');

       -- set unit of measure to the correct value using Thesarus and Mapping tables
       UPDATE NCI_LABS N
          SET UNIT = (SELECT U.VALUE
                        FROM NCI_UOMS U
                       WHERE UPPER(N.UNIT) = UPPER(U.VALUE)
                      UNION
                        SELECT U.PREFERRED
                          FROM NCI_UOM_MAPPING U
                         WHERE UPPER(N.UNIT) = UPPER(U.SOURCE)
                      )
        WHERE LOAD_FLAG IN ('N', 'R') AND N.UNIT IS NOT NULL AND
              N.UNIT != ' ';

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "UNIT".');

       Commit; -- prc 07/14/03  Added commit statement

       -- PRC 08/22/2003: Added Code to Check each record in NCI LABS to see if it does not reach
       --                 the maximum SubEvent Number.

       Log_Util.LogMessage('PLD - Starting Flag Duplicate Lab Result Records.');
       Flag_Dup_Lab_Results;
       Log_Util.LogMessage('PLD - Finished Flag Duplicate Lab Result Records.');
       
       Log_Util.LogMessage('PLD - Starting Check SubEvent Numbers for all Loadable Labs (Check_SubEvent_Numbers).');
       Check_SubEvent_Numbers;
       Log_Util.LogMessage('PLD - Finished Check SubEvent Numbers for all Loadable Labs (Check_SubEvent_Numbers).');

       Commit; -- prc 04/08/04  Added commit statement

       Log_Util.LogMessage('PLD - Finished "PROCESS_LAB_DATA".'); 
            
  END process_lab_data;

  Procedure Process_Batch_Load Is
     /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     /* This section is used to take the Records In NCI_LABS, and process then for  */
     /* Batch Loading.  This procedure was broken out of Process_Lab_Data.          */
     /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     
     labs_count number;
  
  BEGIN
      Log_Util.LogMessage('PBL - Beginning "PROCESS_BATCH_LOAD" (PBL).');

     -- check if there enough 'N' or 'R' records to process, if so continue with loading lab results
      select count(*)
        into labs_count
        from BDL_TEMP_FILES;

      if (labs_count > 0) then
         Log_Util.LogMessage('PBL - There are '||to_char(labs_count)||' records in "BDL_TEMP_FILES" to process for Batch Loading.');

         Log_Util.LogMessage('PBL - Executing "automate_bdl.create_dat_file".');
         automate_bdl.create_dat_file;

         Log_Util.LogMessage('PBL - Finished "automate_bdl.create_dat_file".');
      Else
      
         Log_Util.LogMessage('PBL - There are NO RECORDS in "BDL_TEMP_FILES" to process for Batch Loading.');
      
      end if;
      Log_Util.LogMessage('PBL - Purging LABLOAD Logs < SYSDATE-14.');
      MessageLogPurge('LABLOAD%',SYSDATE - 14);
      Log_Util.LogMessage('PBL - Finished "PROCESS_BATCH_LOAD" (PBL).');
  END;  

END cdw_data_transfer_new;
/
