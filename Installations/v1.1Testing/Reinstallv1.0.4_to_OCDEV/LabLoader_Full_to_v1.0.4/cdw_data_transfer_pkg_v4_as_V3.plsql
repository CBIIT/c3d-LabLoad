CREATE OR REPLACE PACKAGE cdw_data_transfer_v3 AS

  -- Global Package Variables.
     
  Labs_Count      Number; 
   
  Function Find_Lab_Question(i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Varchar2;
  Function Cnt_Lab_Test_Maps(i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Number;
 
  Procedure MessageLogPurge(LogName in Varchar2, LogDate in Date);
  
  Procedure Check_SubEvent_NUmbers;

  Procedure Get_Process_Load_Labs(Process_Type in Varchar2 default 'FULL');
  Function  pull_latest_labs Return Number;
  Function pull_missed_labs Return Number;
  Function pull_Historical_labs_4(PatID in Varchar2) Return Number;

  PROCEDURE identify_duplicate_records; -- Marked Duplicate Records

  PROCEDURE Flag_UPD_Lab_Results(P_Type in Varchar2); 
  Procedure LLI_Processing;
  PROCEDURE prepare_cdw_labs;
  Procedure Identify_Additional_Labs;
  PROCEDURE process_lab_data;
  Procedure Process_Batch_Load;
  
  Procedure Reload_Error_Labs(P_Method in Varchar2 Default 'MARK',
                              E_Study  in Varchar2 Default '%',
                              E_Reason in Varchar2 Default '%',
               E_Patientid in Varchar2 Default '%');
  
  Procedure Process_Error_Labs(P_Method in Varchar2 Default 'MARK');
                              
                              
  Procedure Recheck_Unmapped_Labs(P_Method in Varchar2 Default 'HELP'); -- prc 01/21/2004
  Procedure Update_After_Batch_Load; -- Renamed from Failure to Load
  
  Procedure Pre_Load_Patients ; -- Loads Patient IDS into a table for FASTER processing
  Procedure Populate_Study_Patient; -- Loads all PatientIDs/NCI Instit. Codes to a table. (Union View Replacment)
  Procedure Get_Response(v_Study in Varchar2,
                         v_patient in Varchar2,
                         v_Dcm in Varchar2,
                         v_quest in Varchar2,
                         v_result out varchar2,
                         v_found  out boolean); -- Queries RESPONSES table with these parameters.
  Function Text2Date(v_text in varchar2) return date;
  
END cdw_data_transfer_v3;
/

sho  error


CREATE OR REPLACE PACKAGE BODY cdw_data_transfer_v3 AS
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
  /*  PRC 03/03/2004: 1) Changed primary select.  Sybase Link no longer exists.  Data  */
  /*                  is uploaded to NCI_UPLOAD_SYBASE_LAB_RESULTS, and the query now  */
  /*                  runs against it.                                                 */
  /*                  2) Removed old "commented out" code related to Message Logs      */
  /*  PRC 08/04/2004: 1) Added PULL_HISTORICAL_LABS_4 function to pull lab data from the*/
  /*                  Historical Lab Results table, and channel it into CDW_LAB_RESULTS*/
  /*  PRC 06/16/2005: LLI Enhancements:                                                */ 
  /*                  1) Removed all references to 'R' load type when checking for     */
  /*                     records to process.  'R' must have been hold over to legacy   */
  /*                     version as setting the LOAD_FLAG to 'R' could not be found in */
  /*                     any of the subsequent processes.                              */
  /*                  2) Moved procedure "identify_duplicate_records" from Package     */
  /*                     "insert_lab_data" to here.  More logically correct.           */
  /*                                                                                   */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * - - - - */
  
  Function Text2Date(v_text in varchar2) return date is
     v_hold_date date := Null;
  Begin
     v_hold_date := to_date(SUBSTR(v_text, 1, 8), 'YYYYMMDD');
     
     return v_hold_date;
  Exception
     when others then
        Log_Util.LogMessage('TEXT2DATE ERROR: Unexpected ERROR Occurred in TEXT2DATE('||v_text||').');
        Log_Util.LogMessage('TEXT2DATE ERROR: Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('TEXT2DATE ERROR: Error Message: ' || SQLERRM);
        return NULL;    
  End;

  Procedure Get_Response(v_Study in Varchar2, v_patient in Varchar2, v_Dcm in Varchar2,
                         v_quest in Varchar2, v_result out varchar2, v_found  out Boolean) is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
  /*       Date: 02/09/2006                                                            */
  /*Description: This procedure is used to query the RESPONSES table for a single      */
  /*             result using Study,Patient, DCM Name and Question.  Output is         */
  /*             VALUE_TEXT from responses and Found (Boolean).                        */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*  Modification History                                                             */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  
  Begin                       
     SELECT R1.VALUE_TEXT
       into v_result
       FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
      WHERE D.NAME = v_DCM 
        AND D.DCM_STATUS_CODE = 'A' 
        AND RD.CLINICAL_STUDY_ID = d.CLINICAL_STUDY_ID 
        AND D.DOMAIN = v_Study 
        AND D.DCM_ID = RD.DCM_ID 
        AND d.dcm_subset_sn = rd.dcm_subset_sn
        AND d.dcm_layout_sn = rd.dcm_layout_sn 
        AND D.DCM_ID = Q.DCM_ID 
        AND q.dcm_que_dcm_subset_sn = d.dcm_subset_sn 
        AND q.dcm_que_dcm_layout_sn = d.dcm_layout_sn
        AND R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID
        AND R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID 
        AND R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID
        AND R1.END_TS = RD.END_TS 
        AND R1.END_TS = to_date(3000000, 'J') 
        AND Q.QUESTION_NAME = v_quest 
        AND rtrim(r1.value_text) is not null 
        AND RD.PATIENT = v_patient;

     v_found := TRUE;
     
   EXCEPTION
     WHEN NO_DATA_FOUND then
        v_found := FALSE;
     when others then
        Log_Util.LogMessage('GR - WARNING: Unexpected ERROR Occurred in "Get_Response".');
        Log_Util.LogMessage('     RPED - Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('     RPED - Error Message: ' || SQLERRM);
   End Get_Response;

  Function Find_Lab_Question(i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Varchar2
  is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
  /*       Date: 07/21/2004                                                            */
  /*Description: This procedure is used to identify the OC Lab Question Name, based    */
  /*             upon Test id and Lab Code.  This function was created to handle       */
  /*             processing of new Laboratories.                                       */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*  PRC 08/26/2004 : Added NETTRIALS Lab Check.                                      */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     
     v_oc_Lab_Question  nci_lab_mapping.oc_lab_question%type;
     err_num            number;
     err_msg            varchar2(100);
  
  Begin
     If i_Lab_COde = 'CDW' Then
        Begin
           SELECT DISTINCT M.OC_LAB_QUESTION
                into v_oc_lab_question
                FROM nci_lab_mapping m
               WHERE M.test_component_id = i_test_ID 
                 AND M.laboratory        = i_lab_code
                 and m.oc_lab_question is not null;
              
           Exception      
              WHen No_Data_Found then
                 Begin
                    select distinct OC_LAB_QUESTION
                      into v_oc_lab_question
                      from NCI_CDW_LAB_MAP_CROSSREF
                     WHERE test_ID   =  i_test_ID 
                         AND laboratory = i_lab_code
                         and oc_lab_question is not null;
                         
                   Exception
                      When No_Data_Found Then
                         v_oc_lab_question := NULL;
                      When Others then
                         v_oc_lab_question := NULL;
                         Err_num := SQLCODE;
                         err_msg := substr(sqlerrm,1,100);
                         If Err_Num = -1422 Then
                            Log_Util.LogMessage('FNDLQST2 - ERROR: Test_ID = "'||i_test_id||'" / Laboratory= "'||i_lab_code||'" has duplicate OC_QUESTION Mapping.');
                     Else
                        Log_Util.LogMessage('FNDLQST3 - Error during FIND_LAB_QUESTION');
                        Log_Util.LogMessage('         - Test_ID = "'||i_test_id||'"    Laboratory= "'||i_lab_code||'".');
                        Log_Util.LogMessage('         - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
                     End If;   
               End;
            When Others Then
               v_oc_lab_question := NULL;
                 Log_Util.LogMessage('FNDLQST1 - Error during FIND_LAB_QUESTION');
                     Log_Util.LogMessage('         - Test_ID = "'||i_test_id||'"    Laboratory= "'||i_lab_code||'".');
                     Log_Util.LogMessage('         - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
            End;
     ElsIf (upper(i_Lab_Code) = 'NETTRIALS' or 
            upper(i_Lab_Code) = 'GEORGETOWN' )  Then
        Begin
           SELECT DISTINCT M.OC_LAB_QUESTION
                into v_oc_lab_question
                FROM nci_lab_mapping m
               WHERE M.test_component_id = i_test_ID 
                 AND M.laboratory        = i_lab_code
                 and m.oc_lab_question is not null;
              
        Exception      
           When No_Data_Found then
              v_oc_lab_question := NULL;
           When Others Then
              v_oc_lab_question := NULL;
              Log_Util.LogMessage('FNDLQST4 - Error during FIND_LAB_QUESTION');
              Log_Util.LogMessage('         - Test_ID = "'||i_test_id||'"    Laboratory= "'||i_lab_code||'".');
              Log_Util.LogMessage('         - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
        End;
     Else
        v_oc_lab_question := NULL;
     End If;
     Return v_oc_lab_question;
  End;
 
  Function Cnt_Lab_Test_Maps(i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Number
  is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
     /*       Date: 07/21/2004                                                            */
     /*Description: This procedure is used to identify if the Lab Test is mapped to more  */
     /*             than one OC Lab Question.  Each LABORATORY has it's own way checking  */
     /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     
     v_count   Number;
     err_num   Number;
     err_msg   Varchar2(100);
  
  Begin
     If i_Lab_COde = 'CDW' Then
        Begin
           SELECT count(DISTINCT M.OC_LAB_QUESTION)
                into v_count
                FROM nci_lab_mapping m
               WHERE M.test_component_id = i_test_ID 
                 AND M.laboratory        = i_lab_code
                 and m.oc_lab_question is not null;
               
               if v_count=0 Then
                  SELECT count(DISTINCT OC_LAB_QUESTION)
                      into v_count
                     from NCI_CDW_LAB_MAP_CROSSREF
                    WHERE test_ID   =  i_test_ID 
                      AND laboratory = i_lab_code
                     and oc_lab_question is not null;
               End If;
               
           Exception      
              WHen No_Data_Found then
                 Begin
                    SELECT count(DISTINCT OC_LAB_QUESTION)
                      into v_count
                      from NCI_CDW_LAB_MAP_CROSSREF
                     WHERE test_ID   =  i_test_ID 
                         AND laboratory = i_lab_code
                         and oc_lab_question is not null;
                         
                   Exception
                      When No_Data_Found Then
                         v_count := 0;
                      When Others then
                         v_count := 0;
                         Err_num := SQLCODE;
                         err_msg := substr(sqlerrm,1,100);
                         Log_Util.LogMessage('LtDblMp2 - Error in Function LAB_TEST_DBLE_MAPPED');
                     Log_Util.LogMessage('          - Test_ID = "'||i_test_id||'"    Laboratory= "'||i_lab_code||'".');
                     Log_Util.LogMessage('          - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
                  
               End;
            When Others Then
               v_count := 0;
                 Log_Util.LogMessage('LtDblMp1 - Error in Function LAB_TEST_DBLE_MAPPED');
                     Log_Util.LogMessage('         - Test_ID = "'||i_test_id||'"    Laboratory= "'||i_lab_code||'".');
                     Log_Util.LogMessage('         - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
            End;
         Else
            v_count := 0;
         End If;
      Return v_count;
    End;

  Procedure Process_Lab_Other is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 12/13/2004                                                            */
    /*Description: This procedure is process the mapping of Lab Test to the "Lab Other"  */
    /*             DCM.  In the past, all lab tests that are successfully mapped to an   */
    /* OC lab Question, but that question is not on a Specific DCM as a repeat default,  */
    /* were mapped to the "Other Labs" panel (LAB_ALL/LABA DCM/DCMSubset).  A change was */
    /* requested that this should no longer be the case, and that ANY mapped lab test,   */
    /* regardless of study, that has no panel should be marked with an error. To create  */
    /* more flexability, the code was enhanced to use a study specific identifier to     */
    /* determine which studies will load other labs, and which will not.  By using the   */
    /* study control table NCI_LAB_LOAD_CTL, the column LOAD_OTHER_LABS controls this.   */
    /* A value of 'Y' denotes that lab test should be loaded, while 'N' denotes no load. */
    /* The study 'ALL' contains the default value for all studies not specifically noted */
    /* with an 'N' or 'Y'                                                                */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  
  Begin
  
     For x_Rec in (select a.study, 
                          nvl(b.load_other_labs, c.load_other_labs) load_other_labs
                     from clinical_studies a,
                          nci_lab_load_ctl b,
                          nci_lab_load_ctl c
                    where a.study in (select oc_study from nci_labs
                                       where load_flag in ('N')
                                         and oc_lab_panel is null 
                                         AND oc_lab_subset is null 
                                         AND oc_lab_question is not null 
                                         AND result is not null)
                      and a.study  = b.oc_study(+)
                      and nvl(b.oc_study,'!') <> 'ALL'
                      and c.oc_study = 'ALL'                                )  Loop
                        
        If X_Rec.load_other_labs = 'Y' Then
  
           UPDATE NCI_LABS
              SET OC_LAB_PANEL  = 'LAB_ALL'
                 ,OC_LAB_EVENT  = 'OTHER LABS'
                 ,OC_LAB_SUBSET = 'LABA'
            WHERE oc_study = X_Rec.study
              AND load_flag in ('N')
              and oc_lab_panel is null 
              AND oc_lab_subset is null 
              AND oc_lab_question is not null 
              AND result is not null; 
  
           Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_PANEL", "OC_LAB_EVENT", "OC_LAB_SUBSET"'||
                              ' with LAB_ALL, OTHER LABS and LABA for Study '||X_REc.Study);
                            
        Else                           
                            
           UPDATE NCI_LABS
              SET LOAD_FLAG = 'E', 
                  ERROR_REASON = 'Study '||X_Rec.Study||' does not load "Other Labs".'
            WHERE oc_study = X_Rec.Study
              and LOAD_FLAG IN ('N')
              and oc_lab_panel is null 
              AND oc_lab_subset is null 
              AND oc_lab_question is not null 
              AND result is not null; 
  
           Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                               ' rows marked for error "Study does not load "Other Labs".');
            
        End If;
                    
     End Loop;
        
  End;

  Procedure Populate_LABDCM_EVENTS_Table is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 12/20/2004                                                            */
    /*Description: This procedure is used to populate the Lab DCM Events table with      */
    /*             values from the view NCI_STUDY_LABDCM_EVENTS_VW.  Table is used to    */
    /*             significantly increase the speed of the CDM, EVENT, SUBSET assignment */
    /*             code.  Testing revealed that 48000 records now takes less than 10 min.*/
    /*             compared to hours.                                                    */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  Begin
  
     Log_Util.LogMessage('PLDET - About to delete old records from NCI_STUDY_LABDCM_EVENTS_TB.');

     Delete from NCI_STUDY_LABDCM_EVENTS_TB;
     
     Log_Util.LogMessage('PLDET - '||to_char(SQL%RowCount)||' records removed from NCI_STUDY_LABDCM_EVENTS_TB.');

     Log_Util.LogMessage('PLDET - About to populate table NCI_STUDY_LABDCM_EVENTS_TB.');

     Insert into NCI_STUDY_LABDCM_EVENTS_TB
     select * from NCI_STUDY_LABDCM_EVENTS_VW; 
     
     Log_Util.LogMessage('PLDET - '||to_char(SQL%RowCount)||' records inserted into NCI_STUDY_LABDCM_EVENTS_TB.');

     Log_Util.LogMessage('PLDET - Finished Populate_LABDCM_EVENTS_Table.');

  End;

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


  Procedure Reload_Error_Labs(P_Method in Varchar2 Default 'MARK',
                              E_Study  in Varchar2 Default '%',
                              E_Reason in Varchar2 Default '%',
               E_Patientid in Varchar2 Default '%') is
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
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 06/14/04                                                                  */
    /*    Mod: Added E_Study as an input parameter, to help identify study specific      */
    /*         Error_Reasons needed reprocessed.                                         */
    /*         Added P_Method as an input parameter.  Works similar to the Recheck       */
    /*         Unmapped function.  Added messages for invalid method types, etc.         */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 06/22/04                                                                  */
    /*    Mod: Removed duplicate code that was running the batch load twice and the      */
    /*         data dates twice.               .                                         */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 08/17/05                                                                  */
    /*    Mod: Enhanced Procedure.  Replaced section of code that performed processing   */
    /*         with call to "GET_PROCESS_LOAD_LAB" with the "WAITING" option. There have */
    /*         been alot of modifications to the called procedure.  There should NOT be  */
    /*         2 different locations in the code where loading actually occurrs.         */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /* Author: Sirisha Yerredu -  AC Technologies                                        */
    /*   Date: 10/19/05                                                                  */
    /*    Mod: Enhanced Procedure. Request from Christo to handle Error Labs which       */
    /*         got rejected due to various Error Reasons .Added Additional Parameter     */
    /*         to the procedure.Added E_Patient_id as an Input parameter.Update          */
    /*         Query now performs search based on Study, Error_Reason and Patient_Id     */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 11/10/05                                                                  */
    /*    Mod: Enhanced Procedure.  Added LogExist Check.  Only create new log name if   */
    /*         needed.  New Procedure Process_Error_Labs, calls this procedure during    */
    /*         normal processing, which caused log file to be reset.                     */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 12/08/05                                                                  */
    /*    Mod: Enhanced Procedure.  Added "COUNT" option so that a count of records to   */
    /*         be marked can be retreived.                                               */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    
     v_JobNumber     Number;

  Begin
    If Log_Util.Log$LogName is null Then --prc 11/10/05
       Log_Util.LogSetName('ERRORLABRELOAD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
       MessageLogPurge('ERRORLABRELOAD%',SYSDATE - 14);  -- prc 12/08/05 : Moved to here...makes more sense
    End If; --prc 11/10/05
    Log_Util.LogMessage('ERRREL - Starting "RELOAD_ERROR_LABS".'); -- prc 07/16/03
    Log_Util.LogMessage('ERRREL - Parameters Method ="'||P_Method||'"   Study="'||E_Study||'".'); -- prc 06/14/04
    Log_Util.LogMessage('ERRREL - Parameters Error Reason ="'||E_Reason||'".'); -- prc 06/14/04

    -- If not a valid method, give this message in the log, and do not proceed.
    If Upper(P_Method) not in ('MARK','PROCESS','COUNT') Then
        Log_Util.LogMessage('ERRREL -  Parameter '||P_METHOD||' is not a valid Parameter.');
        Log_Util.LogMessage('ERRREL -  ');
        Log_Util.LogMessage('ERRREL -  Valid Methods for Reload_Error_Labs are ''MARK'' and ''PROCESS''');
        Log_Util.LogMessage('ERRREL -  ');
        Log_Util.LogMessage('ERRREL -  MARK    - Marks the records as "NEW" and resets the field ERROR_REASON.');
        Log_Util.LogMessage('ERRREL -            These records will then wait for the next batch of Lab Loading');
        Log_Util.LogMessage('ERRREL -  COUNT   - Counts the records that would be MARKed.');
        Log_Util.LogMessage('ERRREL -            These records will then wait for the next batch of Lab Loading');
        Log_Util.LogMessage('ERRREL -  PROCESS - Performs the MARK function, but will then process the records');
        Log_Util.LogMessage('ERRREL -            immediately.');
        Log_Util.LogMessage('ERRREL - ');
    Else
       If Upper(P_Method) in ('COUNT') Then  -- prc 12/08/05
          select count(*) into Labs_Count
            from NCI_LABS
           where load_flag = 'E'
             and nvl(oc_study,'~') like E_Study  -- prc 10/26/04 added "nvl" function
             and error_Reason like E_Reason
             and patient_id like E_Patientid; -- sy
         
          Log_Util.LogMessage('ERRREL - '||to_char(labs_count)||' record(s) found.  NOT MARKED');
     
       End If; -- prc 06/14/04
       If Upper(P_Method) in ('MARK','PROCESS') Then  -- prc 06/14/04
          Update NCI_LABS
                  Set Load_flag    = 'N'
                     ,Error_Reason = 'Reloaded due to: ' || Error_Reason
                where load_flag = 'E'
                  and nvl(oc_study,'~') like E_Study  -- prc 10/26/04 added "nvl" function
                  and error_Reason like E_Reason
                  and patient_id like E_Patientid; -- sy
     
          labs_count := SQL%RowCount;
     
          Log_Util.LogMessage('ERRREL - '||to_char(labs_count)||' rows successfully set "Load_Flag=N" and "Error_Reason"');
     
          Commit;
     
       End If; -- prc 06/14/04
    End If; 
       
    If Upper(P_Method) in ('PROCESS') Then  -- prc 08/17/05
       
       Log_Util.LogMessage('ERRREL - Calling "GET_PROCESS_LOAD_LABS(WAITING)".'); -- prc 08/17/05
       Get_Process_Load_Labs('WAITING');                    
              
    End If;
   
    Log_Util.LogMessage('ERRREL - Finished "RELOAD_ERROR_LABS"'); -- prc 07/16/03
          
  End; -- Reload_Error_Labs
  
  
  Procedure Process_Error_Labs(P_Method in Varchar2 Default 'MARK') is   -- added 10/19/2005
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Sirisha Yerredu - AC Technologies                                       */
    /*       Date: 10/19/2005                                                              */
    /*Description: This procedure is used to reset Lab Load records  which got             */     
    /*             errored due to the Error Reason 'PreStudy Lab Date is NULL'       .     */
    /*             This procedure also Resets the Labs which got errored                   */
    /*             before due to Various Error Reasons depending upon the                  */
    /*             parameters passed for the Error_Reason.Cycle is one of the              */
    /*             Attribute of the nci_labs_error_labs which takes 2 values.              */
    /*             R - Refers to Repetetive process which runs every day.                  */
    /*             All Patients which got Error Reason of 'PreStudy Lab Date is NULL'      */ 
    /*             will have cycle value of 'R'.All other patients which have different    */ 
    /*             Error Reasons will have cycle value of 'O' which means one time process */
    /*-------------------------------------------------------------------------------------*/
    /* Modification History:                                                               */
    /* PRC 11/10/2005: Cleaned up the code, added "PEL" to message logs. Added Messages.   */
    /*-------------------------------------------------------------------------------------*/
    /* Modification History:                                                               */
    /* PRC 12/08/2005: Added Parameter to Routine so as to Pass in "COUNT".  Added code so */
    /*                 log file would start here if needed (when run single stand alone).  */
    /*                 Added code to alert of invalid processing methods. added code so    */
    /*                 that MARK processing does the delete.                               */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */   
    
    Begin
       If Log_Util.Log$LogName is null Then -- PRC 12/08/05
          Log_Util.LogSetName('PROCERRLAB_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
          MessageLogPurge('PROCERRLAB%',SYSDATE - 14);  -- PRC 12/08/05
       End If; --prc 11/10/05
       Log_Util.LogMessage('PEL - Starting "Process_Error_Labs"'); -- PRC 12/08/05
       Log_Util.LogMessage('PEL - Parameters Method ="'||P_Method||'".'); -- PRC 12/08/05
  
       -- If not a valid method, give this message in the log, and do not proceed.
       If Upper(P_Method) not in ('MARK','COUNT') Then
           Log_Util.LogMessage('PEL -  Parameter '||P_METHOD||' is not a valid Parameter.');
           Log_Util.LogMessage('PEL -  ');
           Log_Util.LogMessage('PEL -  Valid Methods for Process_Error_Labs are ''MARK'' and ''COUNT''');
           Log_Util.LogMessage('PEL -  ');
           Log_Util.LogMessage('PEL -  MARK    - Marks the records as "NEW" and resets the field ERROR_REASON.');
           Log_Util.LogMessage('PEL -            These records will then wait for the next batch of Lab Loading');
           Log_Util.LogMessage('PEL -  COUNT   - Counts the records to be marked without marking them.');
           Log_Util.LogMessage('PEL - ');
       Else
          For x_Rec in (select oc_study, patient_id, error_reason, cycle
                          from nci_labs_error_labs) Loop 

             Log_Util.LogMessage('PEL - Calling "Reload_Error_Labs", Cycle = "'||X_rec.Cycle||'".');--prc 11/10/05
             Reload_error_labs(P_METHOD,x_Rec.oc_study,x_Rec.error_reason,x_rec.patient_id);
          End loop;
          If P_Method = 'MARK' Then
             Log_Util.LogMessage('PEL - Completed Auto-Processing of Error Labs.');--prc 11/10/05

             Log_Util.LogMessage('PEL - Deleting Single Cycle Requests.');--prc 11/10/05

             Delete from nci_labs_error_labs where upper(cycle) = 'O';
             commit;

             Log_Util.LogMessage('PEL - '||to_char(SQL%RowCount)||' Rows deleted records from nci_labs_error_labs');
          End If;
       End If;
       Log_Util.LogMessage('PEL - Finished "Process_ERROR_LABS"');
     
   EXCEPTION
     WHEN OTHERS THEN
         Log_Util.LogMessage('PEL - Error Encountered: ' || SQLCODE);
         Log_Util.LogMessage('PEL - Error Message: ' || SQLERRM);     
 End;   -- Process_Error_Labs
  
  

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
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 08/17/05                                                                  */
    /*    Mod: Enhanced Procedure.  Replaced section of code that performed processing   */
    /*         with call to "GET_PROCESS_LOAD_LAB" with the "WAITING" option. There have */
    /*         been alot of modifications to the called procedure.  There should NOT be  */
    /*         2 different locations in the code where loading actually occurrs.         */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */     

    v_Jobnumber   Number;
    v_oc_lab_question nci_labs.oc_lab_question%type;

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
           For Xrec in (SELECT count(*) Rec_Count, N.TEST_COMPONENT_ID, N.LABORATORY 
                         FROM nci_labs n 
                        WHERE load_flag = 'E' 
                          AND ERROR_REASON = 'Lab Test is unmapped'
                        Group by N.Test_Component_id, n.laboratory) Loop 
                        
              v_oc_lab_question := cdw_data_transfer_v3.FIND_LAB_QUESTION(Xrec.test_component_id, XRec.laboratory);
              If v_oc_Lab_Question is not null Then          
                 Log_Util.LogMessage('RCKUMP - Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
                                     ' can be mapped to: "'|| V_OC_LAB_QUESTION ||'"  - Records Needing Update: '||
                                      to_char(Xrec.Rec_Count));

                If Upper(P_Method) in ('MARK','PROCESS') Then
                   -- Mark the Records for re-processing
                   Update NCI_LABS n
                      Set Load_flag    = 'N'
                         ,Error_Reason = 'Reloaded due to: ' || Error_Reason
                    where load_flag = 'E'
                      and error_Reason = 'Lab Test is unmapped'
                      and n.test_component_id = Xrec.TEST_COMPONENT_ID
                      and n.laboratory = XRec.Laboratory;
             
                   Log_Util.LogMessage('RCKUMP - '||to_char(SQL%RowCount)||' rows successfully marked for reprocessing.');
          
                   Commit;

                End If;

              Else          
                 Log_Util.LogMessage('RCKUMP - Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
                                     ' STILL NOT MAPPED - Records Needing mapped: '||to_char(Xrec.Rec_Count));
              End If;

          End Loop;


       End If;
       If Upper(P_Method) in ('MARK') Then
          Log_Util.LogMessage('RCKUMP - '||'Records will be processed during next Lab Load Run.');
       End If;

       If Upper(P_Method) in ('PROCESS') Then

          Log_Util.LogMessage('RCKUMP - Finished "RELOAD_ERROR_LABS"');
          Log_Util.LogMessage('RCKUMP - Records will be processed NOW.');

          Get_Process_Load_labs('WAITING');

       End If;

     End If;

     Log_Util.LogMessage('RCKUMP - Recheck Unmapped Labs Finished.');

  End; -- Reload_Error_Labs

  Procedure FindandMark_Updates is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 08/09/2005                                                            */
    /*Description: This procedure is used to identify lab test results that are updates  */
    /*             to existing OC Lab Question values.  This allows for special          */
    /*             processing of updates.                                                */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    
    U_Count Number := 0;
    
  Begin
    If Log_Util.Log$LogName is null Then
       Log_Util.LogSetName('UPDATE_LOADED_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
    End If;
    Log_Util.LogMessage('FMU - Starting FindandMark_Updates.');

    -- prc 08/03/06: Removed all references to question.  It only matters if the sample date was previously 
    --               loaded, not the question.  This way, if a Repeat Default is added, and it needs loaded
    --               to an existing panel, it will load as an UPDATE to the panel.
    update nci_labs n
       set load_flag    = 'W',
           Error_reason = 'Records should be loaded as updates.'
     where load_flag = 'L'    -- Change N to L, because of LLI Processing.
       and exists
           (SELECT n.PATIENT_ID, n.LABTEST_NAME, n.RESULT, n.sample_datetime, rd.dcm_time
              FROM dcms          d, 
                   received_dcms rd
             WHERE d.DOMAIN=n.OC_STUDY
               AND d.NAME=n.OC_LAB_PANEL
               AND d.SUBSET_NAME=n.OC_LAB_SUBSET
               and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
               AND d.dcm_id=rd.dcm_id
               AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
               AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
               and rd.patient = n.oc_patient_pos
               AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd')
               AND rd.DCM_TIME=SUBSTR(n.SAMPLE_DATETIME,7)||'00'
               and Rd.END_TS = to_date(3000000, 'J'));
            
    Log_Util.LogMessage('FMU - '||to_char(SQL%RowCount)||' rows successfully marked as "Load as Update" for existing records.');

    -- Mark records as updates, if a soft-deleted record for the same date is found AND it is the
    -- latest received record.  This removes the problem where a record was applied to a subevent number
    -- but the sample datetime is different from the original.
    update nci_labs n
       set load_flag    = 'S',
           Error_reason = 'Records should be loaded as updates (soft-deleted).'
     where load_flag = 'L'    -- Change N to L, because of LLI Processing.
       and exists
           (SELECT n.PATIENT_ID, n.LABTEST_NAME, n.RESULT, n.sample_datetime, rd.dcm_time
              FROM dcms          d, 
                   received_dcms rd
             WHERE d.DOMAIN=n.OC_STUDY
               AND d.NAME=n.OC_LAB_PANEL
               AND d.SUBSET_NAME=n.OC_LAB_SUBSET
               and d.CLINICAL_STUDY_ID =rd.CLINICAL_STUDY_ID
               AND d.dcm_id=rd.dcm_id
               AND d.DCM_SUBSET_SN=rd.DCM_SUBSET_SN
               AND d.dcm_layout_sn=rd.DCM_LAYOUT_SN
               and rd.patient = n.oc_patient_pos
               AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd')
               AND rd.DCM_TIME=SUBSTR(n.SAMPLE_DATETIME,7)||'00'
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
                                 and rd2.subevent_number    = rd.subevent_number));

    Log_Util.LogMessage('FMU - '||to_char(SQL%RowCount)||' rows successfully marked as "Load as Soft-Delete Update".');

    -- prc 09/22/06: 
    -- Find Records that are marked as soft-deletes that have more than one record per lab test Questions.
    -- Leave the Earliest Lab Test Received marked as Soft-Delete, but mark the rest of them as 
    -- Updates to Loading Records 'D'.
    
    For A_Rec in (select count(*), oc_study, oc_patient_pos, oc_lab_panel, oc_lab_subset, sample_datetime, oc_lab_question
                    from nci_labs
                   where load_flag = 'S'
                   group by oc_study, oc_patient_pos, oc_lab_panel, oc_lab_subset, sample_datetime, oc_lab_question
                  having count(*) > 1) loop
        
       update nci_labs n
          set load_flag    = 'D',
         Error_reason = 'Records should be loaded as updates.'
        where load_flag = 'S'    -- Change N to L, because of LLI Processing.
          and oc_study        = A_Rec.oc_study
          and oc_patient_pos  = A_Rec.oc_patient_pos
          and oc_lab_panel    = A_Rec.oc_lab_panel
          and oc_lab_subset   = A_Rec.oc_lab_subset
          and sample_datetime = A_Rec.sample_datetime
          and oc_lab_question = A_Rec.oc_lab_question
          and cdw_result_id > (select min(cdw_result_id) from nci_labs
                 where load_flag = 'S'
                   and oc_study        = A_Rec.oc_study
                   and oc_patient_pos  = A_Rec.oc_patient_pos
                   and oc_lab_panel    = A_Rec.oc_lab_panel
                   and oc_lab_subset   = A_Rec.oc_lab_subset
                   and sample_datetime = A_Rec.sample_datetime
                   and oc_lab_question = A_Rec.oc_lab_question);

            U_Count := U_Count + SQL%RowCount;
    End Loop;
            
    Log_Util.LogMessage('FMU - '||U_Count||' rows successfully marked as "Load as Update" for loading soft-delete Records.');


    Log_Util.LogMessage('FMU - Finished FindandMark_Updates.');

    Commit;

  End FindandMark_Updates;

  Procedure Update_After_Batch_Load is
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
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 08/29/04                                                                  */
    /*    Mod: Renamed from Failure to Load                                              */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  Begin
    If Log_Util.Log$LogName is null Then
       Log_Util.LogSetName('UPDATE_LOADED_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
    End If;
    Log_Util.LogMessage('UABL - Starting Update_After_Batch_Load.');


    update nci_labs n
       set load_flag    = 'C'
          ,load_date    = sysdate
          ,Error_reason = 'Records Loaded and Verified.'
     where load_flag = 'L' 
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
                AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd') -- change yy to rr
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
                AND rv.REPEAT_SN=rp.REPEAT_SN
                and Rp.END_TS = to_date(3000000, 'J')
                and Rv.END_TS = to_date(3000000, 'J'));
                
    Log_Util.LogMessage('UABL - '||to_char(SQL%RowCount)||' rows successfully marked as Loaded and Verified.');

    Commit;

    update nci_labs n
       set load_flag    = 'C'
          ,load_date    = sysdate
          ,Error_reason = 'Soft-Delete Records Reloaded and Verified .'
     where load_flag = 'S' 
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
                AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd') -- change yy to rr
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
                AND rv.REPEAT_SN=rp.REPEAT_SN
                and Rp.END_TS = to_date(3000000, 'J')
                and Rv.END_TS = to_date(3000000, 'J'));
                
    Log_Util.LogMessage('UABL - '||to_char(SQL%RowCount)||' rows successfully marked as Soft -Delete Reloaded and Verified.');

    Commit;
    
    update nci_labs n 
         set load_flag    = 'U'
            ,load_date    = sysdate
            ,Error_reason = 'Records loaded as updates.'
       where load_flag = 'D' 
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
                AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd') -- change yy to rr
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
                AND rv.REPEAT_SN=rp.REPEAT_SN
                and Rp.END_TS = to_date(3000000, 'J')
                and Rv.END_TS = to_date(3000000, 'J'));

    Log_Util.LogMessage('UABL - '||to_char(SQL%RowCount)||' rows successfully marked as Loaded as Updates and verified (D).');

    Commit;

    update nci_labs n
         set load_flag    = 'U'
            ,load_date    = sysdate
            ,Error_reason = 'Records loaded as updates.'
       where load_flag = 'W' 
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
                AND rd.DCM_DATE=TO_CHAR(TO_DATE(n.SAMPLE_DATETIME,'mmddrrhh24mi'),'yyyymmdd') -- change yy to rr
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
                AND rv.REPEAT_SN=rp.REPEAT_SN
                and Rp.END_TS = to_date(3000000, 'J')
                and Rv.END_TS = to_date(3000000, 'J'));

    Log_Util.LogMessage('UABL - '||to_char(SQL%RowCount)||' rows successfully marked as Loaded as Updates and verified (W).');

    Commit;

    Log_Util.LogMessage('UABL - Finished Update_After_Batch_Load.');

  End; -- Update_After_Batch_Load

Procedure Check_SubEvent_Numbers is
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
         (select Distinct a.oc_study, b.clinical_study_id, a.oc_patient_pos, 
                          a.oc_lab_panel, a.oc_lab_subset
            from nci_labs a
                 ,clinical_studies b
           where b.study = a.OC_STUDY
             and a.load_flag IN ('L')) Loop

         Open Get_event(Cr1.clinical_study_id, Cr1.OC_Lab_Panel, Cr1.OC_Lab_Subset);

         v_max_subEventN := 100; 

         -- Secondary Loop; Get all distinct dates for the Study,Patient,Lab
         For Cr2 in (select distinct sample_datetime
                       from nci_labs a
                      where oc_study       = cr1.oc_study        
                        and oc_patient_pos = cr1.oc_patient_pos
                        and oc_lab_panel   = cr1.oc_lab_panel
                        and oc_lab_subset  = cr1.oc_lab_subset 
                        and load_flag in ('L')
                     ) Loop
         
            Begin
               -- Does this study,patient,lab exist in OC for this date
               -- This checks the ACTIVE record
               Select CLIN_PLAN_EVE_NAME 
                 into d_hold_event
                 from received_dcms a,
                      dcms b
                where a.dcm_id = b.dcm_id
                  and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN         -- prc 04/08/04: Added Subset
                  and a.DCM_layout_SN = b.DCM_layout_SN         -- prc 10/20/04
                  and b.subset_name = cr1.oc_lab_subset         -- prc 04/08/04: Added Subset
                  and a.patient = Cr1.oc_patient_pos
                  and a.clinical_study_id = cr1.Clinical_study_id
                  and b.name = cr1.oc_lab_panel
                  and substr(dcm_date,5,2)||substr(dcm_date,7,2)||substr(dcm_date,3,2)||
                      substr(nvl(dcm_time,'000000'),1,4) = cr2.sample_datetime
                  and a.END_TS = to_date(3000000, 'J');
       
               UPDATE NCI_LABS N
                  SET OC_LAB_EVENT = d_hold_Event
                WHERE oc_study = cr1.oc_study
                  and oc_patient_pos = cr1.oc_patient_pos
                  and oc_lab_panel = cr1.oc_lab_panel
                  and oc_lab_subset= cr1.oc_lab_subset
                  and sample_datetime = cr2.sample_datetime
                  and load_flag in ('L');
       
       
            Exception 
               When No_data_Found Then
                  Begin
                     -- Check again to see if the Sample Date once existed and was soft-deleted
                     -- pick the first EVENT where it was soft-deleted.
                     Select distinct CLIN_PLAN_EVE_NAME 
                       into d_hold_event
                       from received_dcms a,
                            dcms b,
                            NCI_STUDY_ALL_DCMS_EVENTS_VW c
                      where a.dcm_id = b.dcm_id
                        and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN         
                        and a.DCM_layout_SN = b.DCM_layout_SN         
                        and b.subset_name = cr1.oc_lab_subset         
                        and a.patient = Cr1.oc_patient_pos
                        and a.clinical_study_id = cr1.Clinical_study_id
                        and b.name = cr1.oc_lab_panel
                        and substr(dcm_date,5,4)||substr(dcm_date,3,2)||
                            substr(nvl(dcm_time,'000000'),1,4) = cr2.sample_datetime
                        and c.OC_STUDY = a.clinical_study_id
                        and c.dcm_name = b.name
                        and c.subset_name = b.SUBSET_NAME
                        and c.cpe_name = a.clin_plan_eve_name
                        and c.display_sn = (select min(c.display_sn)
                                              from received_dcms a,
                                                   dcms b,
                                                   NCI_STUDY_ALL_DCMS_EVENTS_VW c
                                             where a.dcm_id = b.dcm_id
                                               and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN         
                                               and a.DCM_layout_SN = b.DCM_layout_SN         
                                               and b.subset_name = cr1.oc_lab_subset         
                                               and a.patient = Cr1.oc_patient_pos
                                               and a.clinical_study_id = cr1.Clinical_study_id
                                               and b.name = cr1.oc_lab_panel
                                               and substr(dcm_date,5,4)||substr(dcm_date,3,2)||
                                                   substr(nvl(dcm_time,'000000'),1,4) = cr2.sample_datetime
                                               and c.OC_STUDY = a.clinical_study_id
                                               and c.dcm_name = b.name
                                               and c.subset_name = b.SUBSET_NAME
                                               and c.cpe_name = a.clin_plan_eve_name);

                     UPDATE NCI_LABS N
                        SET OC_LAB_EVENT = d_hold_Event
                      WHERE oc_study = cr1.oc_study
                        and oc_patient_pos = cr1.oc_patient_pos
                        and oc_lab_panel = cr1.oc_lab_panel
                        and oc_lab_subset= cr1.oc_lab_subset
                        and sample_datetime = cr2.sample_datetime
                        and load_flag in ('L');

                  Exception 
                     When no_data_found then
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
                              and load_flag in ('L');

                        Else

                           Loop
                           
                              Fetch Get_Event Into v_Hold_Event, v_hold_dsn;
                              If Get_Event%NOTFOUND Then
                        
                                  Log_Util.LogMessage('CHKSUBEVNT - SubEvent error:"'||cr1.OC_STUDY||'/'||
                                                       cr1.oc_patient_pos||'/'||cr1.oc_lab_panel||'/'||
                                                       cr1.oc_lab_subset||'/'||cr2.sample_datetime||'.');
                                                
                                 UPDATE NCI_LABS N
                                    SET Load_Flag = 'E', Error_Reason = 'SubEvent Has Reached 95+.  Lab Not Loaded.',
                                        OC_LAB_EVENT = v_Hold_Event
                                  WHERE oc_study = cr1.oc_study
                                    and oc_patient_pos = cr1.oc_patient_pos
                                    and oc_lab_panel = cr1.oc_lab_panel
                                    and oc_lab_subset= cr1.oc_lab_subset
                                    and sample_datetime = cr2.sample_datetime
                                    and load_flag in ('L');
                        
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
                                 and a.DCM_layout_SN = b.DCM_layout_SN         -- prc 10/20/04
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
                                 and load_flag in ('L');

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
                           and load_flag in ('L');

                        Log_Util.LogMessage('CHKSUBEVNT - '||to_char(SQL%RowCount)||' rows marked with "OTHER" Error.');
                     
                  End;
            End;
         End Loop;
         
         Close Get_Event;
         
      End Loop;
  
      Log_Util.LogMessage('CHKSUBEVNT - Check SubEvent Numbers Finished.');

   End; -- Check_SubEvent_NUmbers
     
  Function pull_latest_labs Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 08/28/03                                                                  */
  /*    Mod: Altered processing.  If primary select finds no candidates to execute, the*/
  /*         process stops.                                                            */
  /*  PRC 03/03/2004: 1) Changed primary select.  Sybase Link no longer exists.  Data  */
  /*                  is uploaded to NCI_UPLOAD_SYBASE_LAB_RESULTS, and the query now  */
  /*                  runs against it.                                                 */
  /*                                                                                   */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     v_rcount  number := 0;  -- prc 08/28/03

  BEGIN
     Log_Util.LogMessage('PLL - Beginning "PULL_LATEST_LABS".');

     -- Load Prospect Data from the FTPed CDW Data Dump File
     Log_Util.LogMessage('PLL - About to call "cdw_load_lab_FTPdata.Load_Flat_File"');
     cdw_load_lab_FTPdata.Load_Flat_File;

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
        select Result_Id
               ,Patient_id 
               ,Record_DateTime 
               ,Test_id
               ,Test_Code
               ,test_name
               ,test_unit
               ,Order_Id
               ,parent_test_id
               ,order_number
               ,accession
               ,text_result
               ,numeric_result
               ,hi_low_flag
               ,updated_flag
               ,low_range
               ,high_range
               ,Reported_Datetime
               ,Received_Datetime 
               ,Collected_Datetime  
               ,masked
               ,range
               ,specimen_id
               ,specimen_modifier_id
               ,qualitative_dict_id
               ,Inserted_Datetime 
               ,update_datetime 
               ,'N'
               ,sysdate
          from NCI_UPLOAD_SYBASE_LAB_RESULTS;

     Exception
        When Others Then
           Log_Util.LogMessage('PLL - PRIMINS - Error Encountered: ' || SQLCODE);
           Log_Util.LogMessage('PLL - PRIMINS - Error Message: ' || SQLERRM);
            
     End;
     v_rcount := SQL%RowCount;

     Commit;

     Log_Util.LogMessage('PLL - '||to_char(v_rcount)||' rows inserted into "cdw_lab_results" from "NCI_UPLOAD_SYBASE_LAB_RESULTS".');
     Log_Util.LogMessage('PLL - Completed execution of Primary Select');

     Log_Util.LogMessage('PLL - Finished "PULL_LATEST_LABS"');
     
     Return v_Rcount;
     
  END pull_latest_labs;

  Function pull_missed_labs Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 08/02/06                                                                  */
  /*   Desc: The function will check the Current Lab Results table and copy any missed */
  /*         records into the CDW_LAB_RESULTS table.  Records are normally copied to   */
  /*         the table based upon dates.  This routine copies records based upon the   */
  /*         field RESULT_ID.                                                          */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     v_rcount  number := 0;  

  BEGIN
     Log_Util.LogMessage('PML - Beginning "PULL_MISSED_LABS".');

     Log_Util.LogMessage('PML - Beginning Primary INSERT');

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
        select Result_Id
               ,MPI 
               ,Date_Time 
               ,Test_id
               ,Test_Code
               ,test_name
               ,test_unit
               ,Order_Id
               ,parent_test_id
               ,order_number
               ,accession
               ,text_result
               ,numeric_result
               ,hi_low_flag
               ,updated_flag
               ,low_range
               ,high_range
               ,Reported_Datetime
               ,Received_Datetime 
               ,Collected_Datetime  
               ,masked
               ,range
               ,specimen_id
               ,specimen_modifier_id
               ,qualitative_dict_id
               ,Inserted_Datetime 
               ,update_datetime 
               ,'N'
               ,sysdate
         from mis_lab_results_current a
          where exists (select 'X' from NCI_LAB_VALID_PATIENTS b
                         where a.MPI = b.pt_id)
            and not exists (select 'X' from CDW_LAB_RESULTS c
                where a.result_id = c.result_id);

     Exception
        When Others Then
           Log_Util.LogMessage('PML - INSERT - Error Encountered: ' || SQLCODE);
           Log_Util.LogMessage('PML - INSERT - Error Message: ' || SQLERRM);
            
     End;
     v_rcount := SQL%RowCount;

     Commit;

     Log_Util.LogMessage('PML - '||to_char(v_rcount)||' rows inserted into "cdw_lab_results" from "MIS_LAB_RESULTS_CURRENT".');

     Log_Util.LogMessage('PML - Finished "PULL_MISSED_LABS"');
     
     Return v_Rcount;
     
  END pull_missed_labs;
  
  Procedure Populate_Study_Patient Is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 02/06/2006                                                                */
    /*  Descr: UNION VIEW REPLACEMENT                                                    */
    /*         The procedure was created to replace the Patient_ID Union View            */
    /*         This procedure will populate the table nci_study_patient_ids with pt_id   */
    /*         and nci_inst_cd by querying the C3D responses table for the "question"    */
    /*         that each study uses for PT_ID and NCI_INST_CD.                           */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Modification History:                                                             */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

     X_Cnt   Number;
     V_Hold_Statement Varchar2(100);
     
  Begin
     If Log_Util.Log$LogName is null Then
        Log_Util.LogSetName('POPSTUDPAT_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
     End If;
  
     Log_Util.LogMessage('PSP - Starting: Populate_Study_Patient');
     
     Log_Util.LogMessage('PSP - About to truncate table NCI_STUDY_PATIENT_IDS.');
     
     --Remove data from last run.  "TRUNCATE" cannot be directly in PL/SQL, so execute the statement.
     v_Hold_statement := 'Truncate table nci_study_patient_ids';
                        
     execute immediate v_hold_statement;
     
     Log_Util.LogMessage('PSP - Table Truncated.');
  
 
     Log_Util.LogMessage('PSP - Beginning Primary Insertion Loop.');
     -- For every study, that has patients, that have data;
     -- 1st: For every defined study in the control table, use that studies controls
     -- 2nd: For every study not specifical in the control table  use the default controls   
     For X_Rec in (select s.study, s.clinical_study_id, b.patient_id_dcm_name, b.patient_id_quest_name
                     from clinical_studies s,
                          nci_study_patient_ids_ctl b
                    where s.study = b.oc_study
                      and exists (select * from patient_positions d
                                   where d.CLINICAL_STUDY_ID = s.CLINICAL_STUDY_ID
                                     and d.has_data_flag <> 'N')
                   UNION
                   select s.study, s.clinical_study_id, b.patient_id_dcm_name, b.patient_id_quest_name
                     from clinical_studies s,
                          nci_study_patient_ids_ctl b
                    where b.oc_study = 'ALL'
                      and not exists (select 'X' from nci_study_patient_ids_ctl c
                                       where s.study = c.oc_study)
                      and exists (select * from patient_positions d
                                   where D.CLINICAL_STUDY_ID = s.CLINICAL_STUDY_ID
                                     and d.has_data_flag <> 'N') ) Loop

        Begin         
           -- Insert each Study / Patient found into the study patient table, using each studies definition for
           -- the location of the patient id question in C3D. Get the REPEAT_SN so that question group can
           -- be matched up later when getting NCI_INST_CD
           -- Note: Get what the user entered even if it causes and exception.
           Insert into nci_study_patient_ids (OC_STUDY, OC_PATIENT_POS, PT_ID_FUL, REPEAT_SN)       
           SELECT X_Rec.Study, rd.patient, nvl(r1.exception_value_text, r1.value_text), r1.repeat_sn
             FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
            WHERE D.NAME = X_Rec.Patient_id_dcm_name
              AND D.DCM_STATUS_CODE = 'A'  
              AND D.CLINICAL_STUDY_ID = RD.CLINICAL_STUDY_ID 
              and D.clinical_study_id = X_Rec.CLINICAL_STUDY_ID
              and D.DCM_ID = RD.DCM_ID
              AND d.dcm_subset_sn = rd.dcm_subset_sn 
              and d.dcm_layout_sn = rd.dcm_layout_sn 
              and D.DCM_ID = Q.DCM_ID 
              AND q.dcm_que_dcm_subset_sn = d.dcm_subset_sn 
              and q.dcm_que_dcm_layout_sn = d.dcm_layout_sn 
              and R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID 
              and R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID 
              AND R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID 
              AND R1.END_TS = RD.END_TS 
              AND R1.END_TS = to_date(3000000, 'J') 
              AND Q.QUESTION_NAME = X_Rec.Patient_id_quest_name
              AND rtrim(nvl(r1.exception_value_text, r1.value_text)) is not null;
 
        -- If the INSERT can't, give an alert message, but keep going.
        Exception
           When Others Then
              Log_Util.LogMessage('PSP - ERROR: During Insert into NCI_STUDY_PATIENT_IDS.');
              Log_Util.LogMessage('PSP - Error Code:    ' || SQLCODE);
              Log_Util.LogMessage('PSP - Error Message: ' || SQLERRM);
              Log_Util.LogMessage('PSP - Study="'||X_Rec.Study||'".');
        End;
  
     End Loop;
     Log_Util.LogMessage('PSP - Finished Primary Insertion Loop.');
     
     Select count(*) into X_Cnt from nci_study_patient_ids;
     Log_Util.LogMessage('PSP - '||to_Char(x_Cnt)||' record(s) inserted into NCI_STUDY_PATIENT_IDS.');
     
     Log_Util.LogMessage('PSP - Beginning NCI_INST_CD Update Loop.');
     
     -- For every record found from above
     -- 1st: For every defined study in the control table, use that studies controls
     -- 2nd: For every study not specifical in the control table  use the default controls   
     For X_Rec in (select a.oc_study, a.oc_patient_pos, a.repeat_sn,
                       b.nci_inst_cd_dcm_name, b.nci_inst_cd_quest_name
                  from nci_study_patient_ids     a,
                       nci_study_patient_ids_ctl b
                 where a.oc_study = b.oc_study
                union
                select a.oc_study, a.oc_patient_pos, a.repeat_sn,
                       b.nci_inst_cd_dcm_name, b.nci_inst_cd_quest_name
                  from nci_study_patient_ids     a,
                       nci_study_patient_ids_ctl b
                 where b.oc_study = 'ALL'
                   and not exists (select 'X' from nci_study_patient_ids_ctl c
                                    where a.OC_study = c.oc_study) 
                ) Loop
  
        Begin
           -- Update each Study / Patient found above, using each studies definition for
           -- the location of the institution code question in C3D.
           -- Note: Get what the user entered even if it causes and exception.
           Update nci_study_patient_ids
              set NCI_INST_CD_FUL = (SELECT nvl(r1.exception_value_text, r1.value_text)
                                       FROM DCMS D, DCM_QUESTIONS Q, RECEIVED_DCMS RD, RESPONSES R1
                                      WHERE D.NAME = X_Rec.NCI_INST_CD_DCM_NAME
                                        AND D.DCM_STATUS_CODE = 'A'  
                                        AND D.CLINICAL_STUDY_ID = RD.CLINICAL_STUDY_ID 
                                        and D.domain = X_Rec.OC_Study
                                        and D.DCM_ID = RD.DCM_ID
                                        AND d.dcm_subset_sn = rd.dcm_subset_sn 
                                        and d.dcm_layout_sn = rd.dcm_layout_sn 
                                        and D.DCM_ID = Q.DCM_ID 
                                        AND q.dcm_que_dcm_subset_sn = d.dcm_subset_sn 
                                        and q.dcm_que_dcm_layout_sn = d.dcm_layout_sn 
                                        and R1.CLINICAL_STUDY_ID = rd.CLINICAL_STUDY_ID 
                                        and R1.RECEIVED_DCM_ID = RD.RECEIVED_DCM_ID 
                                        AND R1.DCM_QUESTION_ID = Q.DCM_QUESTION_ID 
                                        AND R1.END_TS = RD.END_TS 
                                        AND R1.END_TS = to_date(3000000, 'J') 
                                        AND Q.QUESTION_NAME = X_Rec.NCI_INST_CD_quest_name
                                        and rd.patient = X_Rec.oc_patient_pos
                                        and r1.repeat_sn = X_REc.Repeat_sn)
            where oc_study       = X_Rec.OC_Study
              and oc_patient_pos = X_Rec.OC_Patient_Pos
              and repeat_sn      = X_Rec.Repeat_SN;
              
           -- If the UPDATE doesn't, give an alert and continue.
           Exception
              When Others Then
                 Log_Util.LogMessage('PSP - ERROR: During Update for NCI_INST_CD.');
                 Log_Util.LogMessage('PSP - Error Code:    ' || SQLCODE);
                 Log_Util.LogMessage('PSP - Error Message: ' || SQLERRM);
                 Log_Util.LogMessage('PSP - Study="'||X_Rec.OC_Study||'";  '||
                                     'PatientPos="'||X_Rec.OC_Patient_Pos||'";  '||
                                     'RepeatSN="'||X_Rec.Repeat_SN||'".');
           End;
  
     End Loop;
     Log_Util.LogMessage('PSP - Finished NCI_INST_CD Update Loop.');
       
       
     Log_Util.LogMessage('PSP - Beginning NCI_INST_CD CONST Update Loop.');
  
     -- For every record that does not have a NCI_ISNT_CD:
     -- 1st: Use the Studies define Constant unless it is null
     -- 2nd: Use the Default Constant, unless null, when the study is not specifically defined
     For X_Rec in (select a.oc_study, a.oc_patient_pos, a.repeat_sn,
                          b.nci_inst_cd_const
                     from nci_study_patient_ids     a,           
                          nci_study_patient_ids_ctl b
                    where a.oc_study = b.oc_study
                      and b.nci_inst_cd_const is not null
                      and a.nci_inst_cd_ful is null
                   union  
                   select a.oc_study, a.oc_patient_pos, a.repeat_sn,
                          b.nci_inst_cd_const
                     from nci_study_patient_ids     a,
                          nci_study_patient_ids_ctl b
                    where b.oc_study = 'ALL'
                      and not exists (select 'X' from nci_study_patient_ids_ctl c
                                       where a.OC_study = c.oc_study)
                     and b.nci_inst_cd_const is not null
                     and a.nci_inst_cd_ful is null
                  ) Loop
  
        Begin
           -- Update each Study / Patient found above with the NCI_INST_CD Constant.
           Update nci_study_patient_ids
              set NCI_INST_CD_FUL = X_Rec.Nci_inst_cd_const
            where oc_study       = X_Rec.OC_Study
              and oc_patient_pos = X_Rec.OC_Patient_Pos
              and repeat_sn      = X_Rec.Repeat_SN;

        -- If the UPDATE doesn't, give an alert and continue.
        Exception
           When Others Then
              Log_Util.LogMessage('PSP - ERROR: During Update for NCI_INST_CD Constant.');
              Log_Util.LogMessage('PSP - Error Code:    ' || SQLCODE);
              Log_Util.LogMessage('PSP - Error Message: ' || SQLERRM);
              Log_Util.LogMessage('PSP - Study="'||X_Rec.OC_Study||'";  '||
                                  'PatientPos="'||X_Rec.OC_Patient_Pos||'";  '||
                                  'RepeatSN="'||X_Rec.Repeat_SN||'";  '||
                                  'Constant="'||X_Rec.Nci_inst_Cd_Const||'".');
        End;
  
     End Loop;
     Log_Util.LogMessage('PSP - Finished NCI_INST_CD CONST Update Loop.');
     
     Commit;
       
     Log_Util.LogMessage('PSP - Finished: Populate_Study_Patient');

  End Populate_Study_Patient;
  
  Procedure Pre_Load_Patients is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 10/20/04                                                                  */
  /*  Descr: The procedure was created to resolve the problem with querying against a  */
  /*         view that has the tendacy to become invalid, due to is relying on $CURRENT*/
  /*         views.                                                                    */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Modification History:                                                             */
  /* PRC 06/23/05 : Added variable and code to count records after insert into         */
  /*                NCI_LAB_VALID_PATIENTS                                             */
  /*                Added Logging of Error Code and Message to Exception Section       */
  /* PRC 02/07/06: Added call to Patient Study Populate, which builds a table of all   */
  /*               Study Patients that have PATEINT_IDs. Also corrected a small count  */
  /*               bug.                                                                */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     v_Hold_statement varchar2(300);
     X_cnt            Number;
  
  Begin
    Begin
       Log_Util.LogMessage('PLP - Starting: Pre Load Patients.');
       
       Log_Util.LogMessage('PLP - About to call Populate_Study_Patient'); -- prc 020706
       
       Populate_Study_Patient;                                            -- prc 020706
       
       Log_Util.LogMessage('PLP - About to delete from NCI_LAB_VALID_PATIENTS.');
    
       Delete from NCI_LAB_VALID_PATIENTS;

       Log_Util.LogMessage('PLP - Deleted '||to_char(SQL%RowCount)||' records from NCI_LAB_VALID_PATIENTS');
        
       v_Hold_statement := 'INSERT INTO NCI_LAB_VALID_PATIENTS (PT_ID, PT, STUDY, NCI_INST_CD) '||
                           'select PT_ID, PT, STUDY, NCI_INST_CD from NCI_LAB_VALID_PATIENTS_VW';
                        
       execute immediate v_hold_statement;
       
       Select count(*) into X_cnt from NCI_LAB_VALID_PATIENTS;
       
       Log_Util.LogMessage('PLP - Inserted '||to_char(X_Cnt)||' records into NCI_LAB_VALID_PATIENTS'); -- prc 020706
       
       For x_Rec in (select oc_study, Laboratory from NCI_LAB_LOAD_CTL
                      where oc_study <> 'ALL'
                        and Laboratory is not null) Loop
       
          Update NCI_LAB_VALID_PATIENTS
             set laboratory = X_Rec.Laboratory
           where study = X_Rec.oc_Study;
           
          Log_Util.LogMessage('PLP - Updated '||to_char(SQL%RowCount)||' records with Laboratory '||
                               X_REC.Laboratory||' for study '||X_Rec.oc_Study);
           
       End Loop;
       
       For x_Rec in (select oc_study, Laboratory from NCI_LAB_LOAD_CTL
                      where oc_study = 'ALL'
                        and Laboratory is not null) Loop
       
          Update NCI_LAB_VALID_PATIENTS
             set laboratory = X_Rec.Laboratory
           where laboratory is null;
           
          Log_Util.LogMessage('PLP - Updated '||to_char(SQL%RowCount)||' records with default Laboratory '||
                               X_REC.Laboratory);
           
       End Loop;
     
       Commit;
       Log_Util.LogMessage('PLP - Commit Complete.');
     
     Exception 
       When Others Then
          Log_Util.LogMessage('PLP - ERROR DURING INSERT INTO NCI_LAB_VALID_PATIENTS. ROLLBACK OCCURRED.');
          Log_Util.LogMessage('PLP - Error Code:    ' || SQLCODE);
          Log_Util.LogMessage('PLP - Error Message: ' || SQLERRM);
          Rollback;

     End;
     
     Log_Util.LogMessage('PLP - Finished: Pre Load Patients.');

       
  End Pre_Load_Patients;

  Function pull_Historical_labs_4(PatID in Varchar2) Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Author: Patrick Conrad- Ekagra Software Technologies                              */
  /*   Date: 08/28/03                                                                  */
  /*  Descr: Pulls lab records from the Historical Lab Records Table                   */ 
  /*         CTDEV.MIS_LAB_RESULT_HISTORY, and places them in the CDW_LAB_RESULTS table*/
  /*         for processing.  By passing in the MPI (Patient_ID), only that patient's  */
  /*         labs will be pulled.                                                      */
  /*         This process is needed when the Lab Date is much earlier than expected,   */
  /*         and not found in the Current Lab Results data set.                        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     v_rcount  number := 0;  

  BEGIN
     If Log_Util.Log$LogName is null Then
        Log_Util.LogSetName('PULLHISTLABS_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
     End If;

     Log_Util.LogMessage('PHL4 - Beginning "PULL_HISTORICAL_LABS_4".');
     Log_Util.LogMessage('PHL4 - Processing Patient ID "'||PatID||'".');

     If PatID is not null Then
     
        Log_Util.LogMessage('PHL4 - About to insert data for '||PatID||'.');

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
           select Result_Id
                  ,MPI 
                  ,Date_Time 
                  ,Test_id
                  ,Test_Code
                  ,test_name
                  ,test_unit
                  ,Order_Id
                  ,parent_test_id
                  ,order_number
                  ,accession
                  ,text_result
                  ,numeric_result
                  ,hi_low_flag
                  ,updated_flag
                  ,low_range
                  ,high_range
                  ,Reported_Datetime
                  ,Received_Datetime 
                  ,Collected_Datetime  
                  ,masked
                  ,range
                  ,specimen_id
                  ,specimen_modifier_id
                  ,qualitative_dict_id
                  ,Inserted_Datetime 
                  ,update_datetime 
                  ,'N'
                  ,sysdate
             from MIS_LAB_RESULTS_HISTORY a
            where MPI = PatID
              and Not Exists (select '1' from CDW_LAB_RESULTS b
                              where b.Result_ID = a.result_id);

        Exception
           When Others Then
              Log_Util.LogMessage('PHL4 - PRIMINS - Error Encountered: ' || SQLCODE);
              Log_Util.LogMessage('PHL4 - PRIMINS - Error Message: ' || SQLERRM);

        End;
        v_rcount := SQL%RowCount;

        Commit;

        Log_Util.LogMessage('PHL4 - '||to_char(v_rcount)||' rows inserted into "cdw_lab_results" from "MIS_LAB_RESULTS_HISTORY".');
        Log_Util.LogMessage('PHL4 - Completed execution of Primary Insert');

        Log_Util.LogMessage('PHL4 - Finished "PULL_HISTORICAL_LABS_4"');
     Else
        Log_Util.LogMessage('PHL4 - Patient_ID (MPI) cannot be null.');   
        v_RCount := 0;
     End If;
     
     Return v_Rcount;
     
  END pull_Historical_labs_4;

  Procedure Get_Process_Load_Labs(Process_Type in Varchar2 default 'FULL') Is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* This procedure is used to control the processing of Lab Loading.  This      */
  /* procedure accepts one parameter.  The parameter control which process of    */
  /* the lab loading process should be executed.                                 */
  /* GET_PROC        Get records from Flat Files (Sybase), process them up to the*/
  /*                 point of Batch Loading.  DO NOT BATCH LOAD.                 */
  /*                 DO NOT MARK FOR REVIEW                                      */
  /* BATCH           Batch Load Records contained in NCI_LABS.                   */
  /*                 DO NOT GET RECORDS FROM FLAT FILES                          */
  /* FULL            Get records from FLAT FILES, process them up to the point   */
  /*                 of Batch Loading, perform Batch Loading.                    */
  /* WAITING         Only look at "NEW" records in NCI_LABS, and process them up */
  /*                 to the point of Batch Load, and Batch Load them.            */
  /*                 DO NOT GET RECORDS FROM FLAT FILES.                         */
  /* GET_PROC_MARK   Get records from Flat Files, process them upto the point    */
  /*                 of Batch Loading, mark study records needing REVIEW.        */
  /*                 DO NOT BATCH LOAD.                                          */
  /* WAIT_PROC       Only look at "NEW" records in NCI_LABS, and process them up */
  /*                 to the point of Batch Load.DO NOT BATCH LOAD.               */
  /*                 DO NOT MARK FOR REVIEW. DO NOT GET RECORDS FROM FLAT FILES. */
  /* WAIT_PROC_MARK  Only look at "NEW" records in NCI_LABS and process them up  */
  /*                 to the point of Batch Load.  Marm records for REVIEW.  DO   */
  /*                 NOT BATCH LOAD.  DO NOT GET RECORDS FROM FLAT FILES.        */
  /*-----------------------------------------------------------------------------*/
  /* Modification History:                                                       */
  /* PRC 08/19/04: Added Paramter to allow for running of 'NEW' items, without   */
  /*               loading addtional records. 'WAITING' is new parameter         */
  /*-----------------------------------------------------------------------------*/
  /* PRC 10/19/04: Added Paramter to allow for running of 'NEW' items, without   */
  /*               loading addtional records, same as above, with the option to  */
  /*               only process upto and excluding the actual load.              */
  /*               'WAIT_PROC' is new parameter                                  */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 

     v_MISCount      Number := 0;
     v_MISCount2     Number := 0;
     v_NEWCount      Number := 0;
     v_JobNumber     Number;
     v_Process_Type  Varchar2(20);
     
  Begin
     v_Process_Type := Substr(Upper(Process_Type),1,20);
     
     Log_Util.LogSetName('LABLOAD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
     Log_Util.LogMessage('GPLL - Beginning "GET_PROCESS_LOAD_LABS".');
     Log_Util.LogMessage('GPLL - Processing Type is "'||v_Process_Type||'".');
     Commit;

     If v_Process_Type in ('GET_PROC','FULL', 'WAITING','WAIT_PROC', 'GET_PROC_MARK','WAIT_PROC_MARK') Then
        Pre_Load_Patients; -- prc 10/20/04 
     End If;

     If v_Process_Type in ('GET_PROC', 'FULL', 'GET_PROC_MARK') Then
        
        -- Pull the MIS Labs from Flat Files.
        Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.pull_latest_labs"');
        v_MISCount := Pull_Latest_labs;

        Log_Util.LogMessage('GPLL - Checking for Missed Result Ids'); -- prc 08/01/06
        v_MISCount2:= Pull_missed_labs;

        /* Moved up from below.*/
        Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer.prepare_cdw_labs"');
        prepare_cdw_labs;

        Log_Util.LogMessage('GPLL - Latest Pull found '||to_Char(v_MISCOunt)||' record(s).');
     End If;
     
     If v_Process_Type in ('GET_PROC','FULL', 'WAITING','WAIT_PROC', 'GET_PROC_MARK','WAIT_PROC_MARK') Then

        Identify_Additional_Labs; -- prc 08/10/06: Additional records should be created, regardless of RAW.
        
        Select Count(*) 
          into v_NEWCount 
          from NCI_LABS
         where load_flag = 'N';
         
        Log_Util.LogMessage('GPLL - "NEW" NCI_LABS records to process '||to_Char(v_NewCount)||'.');
         
        If (v_MISCount+v_NEWCount) > 0 Then 
  
           -- moved up.  This should be with Flat file pull, since it only allpies to this.
           -- Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer.prepare_cdw_labs"');
           -- prepare_cdw_labs;
  
           Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer.process_lab_data"');
           process_lab_data;
  
        Else 
           Log_Util.LogMessage('GPLL - 0 candidate records in NCI_LABS.  Process Stopping.');
        End If;
     End If;

     If v_Process_Type in ('WAITING', 'FULL','GET_PROC_MARK','WAIT_PROC_MARK') Then

        Select Count(*) 
          into v_NEWCount 
          from NCI_LABS
         where load_flag in ('N','R');
         
        Log_Util.LogMessage('GPLL - "NEW" NCI_LABS records to process '||to_Char(v_NewCount)||'.');
         
        If (v_NEWCount) > 0 Then 
           Log_Util.LogMessage('GPLL - About to call "LLI_Processing".');
           LLI_Processing;

           -- Identify Updates to Loaded Records.
           Log_Util.LogMessage('GPLL - About to call "FindandMark_Updates".');
           FindandMark_Updates;
                       
           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('L'); -- 06/21/05 : LLI Process
         
           Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records ready for LOAD as NEW.');

           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('S'); -- 08/18/06 
         
           Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records ready for RELOAD for Soft-Deletes.');

           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('W'); -- 08/17/05 : Update Records
         
           Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records ready for LOAD as UPDATES.');

           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('R'); -- 06/21/05 : LLI Process
         
           Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records ready for REVIEW.');

        Else 
           Log_Util.LogMessage('GPLL - 0 candidate records in NCI_LABS.  Process Stopping.');
        End If;
     End If;

        
     If v_Process_type in ('FULL', 'WAITING') Then
        -- Check Count
        select count(*)
          into labs_count
          from NCI_LABS
         where load_flag in ('L');

        -- If there are Loadable Records, process them for Upload.
        If labs_count > 0 Then
           Log_Util.LogMessage('GPLL - '||to_char(labs_Count)||' records need processed for Loading.');

           -- Check for Updates within the Loadable Data
           Log_Util.LogMessage('GPLL - Checking for Update records in the batch fo "To Load" Records.');
           Flag_UPD_Lab_Results('L');  
           Log_Util.LogMessage('GPLL - Check.');
       
           -- Check Maximum SubEvent Number.       
           Log_Util.LogMessage('GPLL ****** Starting Check SubEvent Numbers for all Loadable Labs.');
           Check_SubEvent_Numbers;
           Log_Util.LogMessage('GPLL ****** Finished Check SubEvent Numbers for all Loadable Labs.');

           -- Commit
           Commit; 
        End If;

        Log_Util.LogMessage('GPLL - Processing LOAD and UPDATE records.');    
        select count(*)
          into labs_count
          from NCI_LABS
         where load_flag in ('L', 'D', 'W', 'S'); -- prc 08/1806: Added 'S'

        Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' lab records to Process for Loading.');
   
        If labs_count > 0 then

           -- UPDATE RECORDS (Previously Loaded)
           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('W');

            Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' "UPDATE" lab records to Process.');
   
            If labs_count > 0 then
               Log_Util.LogMessage('GPLL - Checking for Multiple Update records in the batch of "Update" Records.');
          Flag_UPD_Lab_Results('W');  
          Log_Util.LogMessage('GPLL - Check.');

               Log_Util.LogMessage('GPLL - Executing Update Existing - "load_lab_results_upd(W)".');
               DELETE FROM BDL_TEMP_FILES;
               Log_Util.LogMessage('GPLL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to load.');
               load_lab_results_upd('W');
               Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.Process_Batch_Load"');
               cdw_data_transfer_v3.Process_Batch_Load;
            End If;

           -- RE-LOAD RECORDS (Soft-Deleted Reloads)
           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('S');

            Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' "Soft-Delete" lab records to reload.');
   
            If labs_count > 0 then
               Log_Util.LogMessage('GPLL - Checking for Update Records in the batch of "Soft-Delete" Records.');
          Flag_UPD_Lab_Results('S');  
          Log_Util.LogMessage('GPLL - Check.');

               Log_Util.LogMessage('GPLL - Executing Update Existing - "load_lab_results(S)".');
               DELETE FROM BDL_TEMP_FILES;
               Log_Util.LogMessage('GPLL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to load.');
               load_lab_results('S');
               Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.Process_Batch_Load"');
               cdw_data_transfer_v3.Process_Batch_Load;
            End If;
           
           -- NEW RECORDS
           select count(*)
             into labs_count
             from NCI_LABS
            where load_flag in ('L');

            Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' "NEW" lab records to Process.');
   
            If labs_count > 0 then
              Log_Util.LogMessage('GPLL - Executing NEW Record Load - "load_lab_results(L)".');
              DELETE FROM BDL_TEMP_FILES;
              Log_Util.LogMessage('GPLL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to load.');
              load_lab_results('L');
              Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.Process_Batch_Load"');
              cdw_data_transfer_v3.Process_Batch_Load;
           End If;

           Log_Util.LogMessage('GPLL - Processing Updates of Records found in current batch.');
           -- The problem is that BDL does not like batch data files having more than one response for the same key.
           -- To alleviate this problem, a study/patient/panel/sampledate time/lab test cannot be in a batch file
           -- more than once.  This routine loops through all available records, making sure that there are no 
           -- duplicates in the batch to be process.  Records are processed in the order they are received.
           Loop
              -- LOAD RECORDS (FOR NEWLY INSERTED ABOVE)
              select count(*)
                into labs_count
                from NCI_LABS
               where load_flag in ('D');

              exit when labs_count = 0;
              
              -- Set ALL Updates In batch to normal Update Status. 
              Update nci_labs set load_flag = 'W' where Load_Flag = 'D';
              
              -- Check for Multiple Updates within the Update Records,  Any Multiple is set to 'D' for reprocessing
              -- while 'W' will fall through and process for loading.
              Log_Util.LogMessage('GPLL - Checking for Update records in the batch of "Update to New" Records.');
              Flag_UPD_Lab_Results('W');  
              Log_Util.LogMessage('GPlL - Check Finsihed.');
           
              -- UPDATE RECORDS (FOR 'L','S', D' and 'W' records above)
              select count(*)
                into labs_count
                from NCI_LABS
               where load_flag in ('W');

              Log_Util.LogMessage('GPLL - There are '||to_char(labs_count)||' "UPDATES TO PROCESSED" lab records to Process.');
   
              If labs_count > 0 then
                 Log_Util.LogMessage('GPLL - Loading Updates Existing in Batch - "load_lab_results(W)".');
                 DELETE FROM BDL_TEMP_FILES;
                 Log_Util.LogMessage('GPLL - '||to_char(SQL%RowCount)||' rows deleted from "BDL_TEMP_FILES" prior to load.');
                 load_lab_results_upd('W');
                 Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.Process_Batch_Load"');
                 cdw_data_transfer_v3.Process_Batch_Load;
              Else
                 Exit;
              End If;
           End Loop;
           
        Else
           Log_Util.LogMessage('GPLL - There are no records in "NCI_LABS" to process for Loading.');
        End If;
     End If;
     
     If (v_Process_type ='BATCH') Then
        
        Log_Util.LogMessage('GPLL - About to call "cdw_data_transfer_v3.Process_Batch_Load"');
        cdw_data_transfer_v3.Process_Batch_Load;

     End If;
     
     /*
     If (V_Process_type in ('FULL','WAITING', 'BATCH')) Then

        Log_Util.LogMessage('GPLL - Sumbitting "ctvw_pkg.p_ct_data_dt"');  -- 01/23/04 now batch
        DBMS_JOB.Submit(v_jobnumber,'Begin ctvw_pkg.p_ct_data_dt; End;');  -- 01/23/04 now batch
        Log_Util.LogMessage('GPLL - Sumbitted "ctvw_pkg.p_ct_data_dt" Job Number='||v_jobnumber); -- 01/23/04 now batch
        
     End If;
     */
    
     If v_Process_Type not in ('GET_PROC','BATCH','FULL','WAITING','WAIT_PROC', 'GET_PROC_MARK','WAIT_PROC_MARK') Then
        Log_Util.LogMessage('GPLL - Invalid Processing type.  Choose "GET_PROC", "BATCH", "FULL", "WAITING", "WAIT_PROC"');     
        Log_Util.LogMessage('GPLL -  "GET_PROC"       - Get New Records from RAW data files, process data, DO NOT Batch Load into OC.');     
        Log_Util.LogMessage('GPLL -  "GET_PROC_MARK"  - Get New Records from RAW data files, process data, mark for LLI, DO NOT Batch Load into OC.');     
        Log_Util.LogMessage('GPLL -  "BATCH"          - Batch Load into OC any existing records');     
        Log_Util.LogMessage('GPLL -  "FULL"           - Get New Records from RAW data File, process data, Batch Load into OC.');     
        Log_Util.LogMessage('GPLL -  "WAITING"        - DO NOT get New Records from Raw data files, process data, Batch Load into OC.');     
        Log_Util.LogMessage('GPLL -  "WAIT_PROC"      - DO NOT get New Records from Raw data files, process data, DO NOT Batch Load into OC.');
        Log_Util.LogMessage('GPLL -  "WAIT_PROC_MARK" - DO NOT get New Records from Raw data files, process data, mark for LLI, DO NOT Batch Load into OC.');
     End If;  

     Log_Util.LogMessage('GPLL - Finished "GET_PROCESS_LOAD_LABS".');

     Commit;
     
  End Get_Process_Load_Labs;

  PROCEDURE prepare_cdw_labs IS
  BEGIN
    DECLARE

      curr_pt           number(10);  
      last_pt           number(10);  
      lab_count         number(10);
      -- oc_pt             varchar2(10);  -- prc 09/30/05 removed per biopharm
      -- oc_study_dom      varchar2(15);  -- prc 09/30/05 removed per biopharm
      check_max         char(1);
      -- prestudy_lab_date date;  -- prc 09/30/05 removed per biopharm
      -- pt_enrollment_dt  date;  -- prc 09/30/05 removed per biopharm

  /* -- Removed Cursor because it is no longer used...will delete later.
     -- PRC 09/30/05 per biopharm
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

      c1_record c1%ROWTYPE; */

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
  /* PRC - 06/21/2005:                                                   */
  /* LLI Enhancements; Moved here from "insert_lab_data" package.        */
  /* Removed references to 'R' load_flag types                           */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 06/05/2006:                                                   */
  /* Altered first duplicate checker so that it only counts distinct     */
  /* record ids that need marked as duplicates.                          */
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
        and a.OC_Patient_Pos = b.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
        and a.sample_datetime = b.sample_datetime
        and a.labtest_name = b.labtest_name
        and a.result = b.result
        and nvl(a.unit,'~')   = nvl(b.unit,'~')
        and a.LOAD_FLAG IN ('N','D')  -- New or Duplicate
        and b.load_flag in ('C','U','L'); -- Loaded or Updated
       
     Cursor C2 is
     select  a.record_id
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
      where a.LOAD_FLAG IN ('N','D')
      order by a.oc_study, a.oc_patient_pos, a.sample_datetime, 
               a.oc_lab_question, a.result, a.unit, a.patient_id; --changed to oc_lab_question from labtes_name
  
     c1_record c1%ROWTYPE;
     c2_record c2%ROWTYPE;
  
  BEGIN
    
     Log_Util.LogMessage('IDR - Checking Exact Dup. against already loaded.');
     x_cnt := 0;

     last_record_id := 0;
     --  Each record found needs to be marked as a duplicate.
     OPEN c1;
     LOOP
        FETCH c1 INTO c1_record;
        EXIT WHEN c1%NOTFOUND;
  
        -- PRC 06/06/06: Modified. Was counting records based on a cartisean product, making it appear
        --               that more records were affected.
        If Last_Record_id <> c1_record.record_id then
           
           update nci_labs 
              set load_flag = 'X', 
                  error_reason = 'Exact Record Match Error with Loaded ('||c1_record.loaded_rec_id||')'
            where oc_study = c1_record.oc_study
              and record_id = c1_record.record_id;
           
           last_record_id := c1_record.record_id;
           
           x_Cnt := X_Cnt + 1;
        End If;
        
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
    
   
        if (c2_RECORD.oc_study       = last_oc_study)       AND
           (c2_record.oc_patient_pos = last_oc_patient_pos) AND
           (c2_record.sample_datetime= last_sample_dt)      AND
           (c2_record.l_question     = last_question)       AND
           (c2_record.result         = last_result)                   then
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
  
  PROCEDURE Flag_UPD_Lab_Results (P_Type in Varchar2) AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This code is used to mark duplicates within the Lab Records waiting to*/
  /*             to be loaded.  These "Duplicates" are actually UPDATES to already     */
  /*             loaded data.                                                          */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 10/27/04 : Rewrote this routine.  Now it is Much more straight forward      */
  /*                  Get all "NEW" lab results, order them by                         */
  /*                  study/patient/sample/question; loop through if last = current    */
  /*                  then mark current as dup.                                        */
  /* LLI Enhancements; Moved here from single procedure "Flag_Dup_Lab_Results".        */
  /* Removed references to 'R' load_flag types                                         */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  
     R_Count       Number := 0;
  
     last_study           nci_labs.oc_study%type;
     last_pat_pos         nci_labs.oc_Patient_Pos%type;
     last_sample_datetime nci_labs.sample_datetime%type;
     last_lab_question    nci_labs.oc_lab_question%type;
     last_record_id       nci_labs.Record_ID%type;
  
     CURSOR c1 is
        SELECT record_id
               ,sample_datetime
               ,result
               ,unit
               ,oc_lab_question
               ,oc_patient_pos
               ,oc_study
               ,nvl(cdw_result_id,record_id)
          FROM nci_labs n
         WHERE LOAD_FLAG IN (P_Type)
         ORDER BY oc_study
                  ,oc_patient_pos
                  ,sample_datetime
                  ,oc_lab_question
                  ,nvl(cdw_result_id,record_id);
  
     c1_record c1%ROWTYPE;
  
  BEGIN
    
     If Log_Util.Log$LogName is null Then 
        Log_Util.LogSetName('FNDDUP_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
     End If;
     Log_Util.LogMessage('FDLLP - Flag Update Lab Results Started');
  
     last_study           := '~';
     last_pat_pos         := 0;
     last_sample_datetime := '~';
     Last_lab_question    := '~';
     Last_record_id       := 0;
     
     R_Count := 0;
  
     OPEN c1;
     LOOP
        FETCH c1 INTO c1_record;
        EXIT WHEN c1%NOTFOUND;
    
        If (Last_study           = c1_Record.oc_study) AND
           (Last_pat_pos         = c1_Record.oc_patient_pos) and
           (Last_Sample_datetime = c1_Record.Sample_datetime) and
           (Last_lab_Question    = c1_Record.Oc_Lab_Question) 
        Then
           update nci_labs
              set load_flag = 'D', 
                  error_reason = 'Study/Patient/DateTime/Question Duplicate (UPDATE) ['||Last_Record_id||']'
            where oc_study = c1_record.oc_study
              and record_id = c1_record.record_id;
                  
           R_count := R_Count + 1;
        else
           null;
        end if;
    
        Last_study           := c1_Record.oc_study;
        Last_pat_pos         := c1_Record.oc_patient_pos;
        Last_Sample_datetime := c1_Record.Sample_datetime;
        Last_lab_Question    := c1_Record.Oc_Lab_Question;
        Last_record_id       := c1_Record.Record_ID;
      
     END LOOP;
  
     Log_Util.LogMessage('FDLLR - '||to_char(R_Count)||' records marked for Lab Panel/Subset/Pt/DtTm/Q Update');
  
     CLOSE c1;
  
     Log_Util.LogMessage('FDLLP - Flag Update Lab Results Finished');
  
  END Flag_UPD_Lab_Results;

  Procedure Identify_Additional_Labs is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* This section is used to added additional records to NCI_LABS for processing */
  /* by identifying new study/patients relationships for existin patients.  Also */
  /* resets those errors held in the automatic error reset control table.        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  
      Hold_unit  nci_labs.unit%type;
      X_Cnt      Number := 0;
  Begin
     process_error_labs;  -- added 10/19/2005
  
     -- Set the study and patient position for those NEW records that do not have either.
     update nci_labs
        set (oc_patient_pos, oc_study) = (select pt, Study
                                            from nci_lab_valid_patients
                                           WHERE PT_ID = nci_labs.PATIENT_ID
                                             and laboratory = nci_labs.laboratory -- prc 12/08/04
                                             and rownum = 1    )
      WHERE LOAD_FLAG IN ('N')
        and (oc_patient_pos is null or oc_study is null);
  
     Log_Util.LogMessage('IAL - '||to_char(SQL%RowCount)||' rows successfully set "oc_patient_pos" and "oc_study"');
         
     -- Generate additional lab records for patient on more than one study.or on same study more than once.
     Begin
        Log_Util.LogMessage('IAL - Starting Additional Record Inserts');
         
        For x_Rec in (select distinct 
                             NULL RECORD_ID         ,PATIENT_ID
                             ,SAMPLE_DATETIME       ,TEST_COMPONENT_ID
                             ,b.LABORATORY          ,LABTEST_NAME
                             ,LAB_GRADE             ,RESULT
                             ,NULL UNIT             ,NORMAL_VALUE
                             ,PANEL_NAME            ,PATIENT_NAME
                             ,COMMENTS              ,NULL OC_LAB_PANEL
                             ,NULL OC_LAB_QUESTION  ,NULL OC_LAB_EVENT
                             ,T.PT OC_PATIENT_POS   ,NULL LOAD_DATE
                             ,'N' LOAD_FLAG         ,RECEIVED_DATE
                             ,NULL DATE_CREATED     ,NULL DATE_MODIFIED
                             ,NULL CREATED_BY       ,NULL MODIFIED_BY
                             ,TEST_CODE             ,CDW_RESULT_ID
                             ,T.STUDY OC_STUDY      ,NULL ERROR_REASON
                             ,NULL OC_LAB_SUBSET
                        from NCI_LAB_VALID_PATIENTS T, -- from patient_id_ptid_vw T, -- prc 10/20/04
                             nci_labs b
                       WHERE T.PT_ID = b.PATIENT_ID
                         and t.laboratory = b.laboratory
                         and b.cdw_result_id is not null
                      MINUS
                      select NULL RECORD_ID         ,PATIENT_ID
                             ,SAMPLE_DATETIME        ,TEST_COMPONENT_ID
                             ,LABORATORY             ,LABTEST_NAME
                             ,LAB_GRADE              ,RESULT
                             ,NULL UNIT              ,NORMAL_VALUE
                             ,PANEL_NAME             ,PATIENT_NAME
                             ,COMMENTS               ,NULL OC_LAB_PANEL
                             ,NULL OC_LAB_QUESTION   ,NULL OC_LAB_EVENT
                             ,OC_PATIENT_POS         ,NULL LOAD_DATE
                             ,'N' LOAD_FLAG          ,RECEIVED_DATE
                             ,NULL DATE_CREATED      ,NULL DATE_MODIFIED
                             ,NULL CREATED_BY        ,NULL MODIFIED_BY
                             ,TEST_CODE              ,CDW_RESULT_ID
                             ,OC_STUDY               ,NULL ERROR_REASON
                             ,NULL OC_LAB_SUBSET
                         from nci_labs b)  LOOP
        Begin
           X_Cnt := X_Cnt + 1;
               
           Begin
              Hold_Unit := Null;
         
              For y_Rec in (select unit 
                              from nci_labs
                             where cdw_result_id = x_rec.cdw_result_id
                               and unit is not null
                             order by record_id) Loop
         
                 Hold_Unit := Y_Rec.Unit;
              End Loop;
         
           Exception
              When No_Data_Found Then
                 Hold_Unit := NULL;
           End;
               
           Insert into NCI_LABS 
                  (RECORD_ID,      PATIENT_ID,       SAMPLE_DATETIME,       TEST_COMPONENT_ID,      
                   LABORATORY,     LABTEST_NAME,     LAB_GRADE,             RESULT,
                   UNIT,           NORMAL_VALUE,     PANEL_NAME,            PATIENT_NAME,
                   COMMENTS,       OC_LAB_PANEL,     OC_LAB_QUESTION,       OC_LAB_EVENT,
                   OC_PATIENT_POS, LOAD_DATE,        LOAD_FLAG,             RECEIVED_DATE,
                   DATE_CREATED,   DATE_MODIFIED,    CREATED_BY,            MODIFIED_BY,
                   TEST_CODE,      CDW_RESULT_ID,    OC_STUDY,              ERROR_REASON,
                   OC_LAB_SUBSET)
           Values (X_Rec.RECORD_ID,      X_Rec.PATIENT_ID,    X_Rec.SAMPLE_DATETIME, X_Rec.TEST_COMPONENT_ID,
                   X_Rec.LABORATORY,     X_Rec.LABTEST_NAME,  X_Rec.LAB_GRADE,       X_Rec.RESULT,
                   Hold_Unit,            X_Rec.NORMAL_VALUE,  X_Rec.PANEL_NAME,      X_Rec.PATIENT_NAME,
                   X_Rec.COMMENTS,       X_Rec.OC_LAB_PANEL,  X_Rec.OC_LAB_QUESTION, X_Rec.OC_LAB_EVENT,
                   X_Rec.OC_PATIENT_POS, X_Rec.LOAD_DATE,     X_Rec.LOAD_FLAG,       X_Rec.RECEIVED_DATE,
                   X_Rec.DATE_CREATED,   X_Rec.DATE_MODIFIED, X_Rec.CREATED_BY,      X_Rec.MODIFIED_BY,
                   X_Rec.TEST_CODE,      X_Rec.CDW_RESULT_ID, X_Rec.OC_STUDY,        X_Rec.ERROR_REASON,
                   X_Rec.OC_LAB_SUBSET); 
        End;
        End loop;
          
        Log_Util.LogMessage('IAL - Finished Additional Record Inserts.');
         
     End;
         
     Log_Util.LogMessage('IAL - Generated additional '||to_char(X_Cnt)||
                             ' lab records for patients on more than one study, or on same study more than once.');
  End Identify_Additional_Labs;

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
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 01/24/06 : Replace single "Map Lab Test Question" update code with 4 new    */
  /*                  update statement to provide mechanism to copy LABTEST_NAME to    */
  /*                  OC_LAB_QUESTION.                                                 */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     
      T_Counter   Number := 0;
      U_Counter   Number := 0;
      I_Counter   Number := 0;
      crnt_ptid   nci_labs.Patient_id%type;
      crnt_Study  nci_labs.OC_Study%type;
      crnt_OFF_OffSet_Days Number := 0;
      v_off_study_dcm   varchar2(30); -- prc 09/09/04: DCM where the off study question is
      v_off_study_quest varchar2(30); -- prc 09/09/04: Name of off study question
      pt_enrollment_dt  Date;
      OffStudy_Date     Date;
      Prestudy_Lab_Date Date;
      dummy       varchar2(1); 
      v_result    responses.value_text%type;
      v_found     boolean := False;
      
      v_date_check_code            nci_lab_load_ctl.DATE_CHECK_CODE%type; 
      v_offstudy_dcm               nci_lab_load_ctl.OFF_STUDY_DCM%type; 
      v_offstudy_quest             nci_lab_load_ctl.OFF_STUDY_QUEST%type;
      v_OffStudy_Offset            nci_lab_load_ctl.OFF_STUDY_OFFSET_DAYS%type;
      v_Prestudy_Dcm               nci_lab_load_ctl.PRESTUDY_LAB_DATE_DCM%type;
      v_Prestudy_Quest             nci_lab_load_ctl.PRESTUDY_LAB_DATE_QUEST%type; 
      v_Prestudy_Offset            nci_lab_load_ctl.PRESTUDY_OFFSET_DAYS%type;
      v_blank_prestudy_use_enroll  nci_lab_load_ctl.BLANK_PRESTUDY_USE_ENROLL%type;
      v_enrollment_dcm             nci_lab_load_ctl.ENROLLMENT_DATE_DCM%type;
      v_enrollment_quest           nci_lab_load_ctl.ENROLLMENT_DATE_QUEST%type;

      Use_Enroll Varchar2(1)  := Null; -- "Use Enroll Date when Prestudy Date Null" Flag

    BEGIN
       Log_Util.LogMessage('PLD - Beginning "PROCESS_LAB_DATA".');
       
       /* Moved code the generated new records and reset error records to its own procedure */
       
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 04/13/04: Moved Section to Here (After Insert of "On More Than One Study"     */
       /* PRC 04/07/04: Added Section                                                       */
       /* Data Contraint Section.  Remove Records for Studies that have stopped loading labs*/
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       
       -- Mark Records as Rejected where the study is flagged to stop loading
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', 
              ERROR_REASON = 'Study is no longer loading labs. (NCI_LAB_LOAD_CTL.STOP_LAB_LOAD_FLAG=''Y'')'
        WHERE LOAD_FLAG IN ('N')
          AND OC_STUDY IN (select OC_STUDY from NCI_LAB_LOAD_CTL
                            where STOP_LAB_LOAD_FLAG = 'Y');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Study is no longer loading labs"');
       
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       /* PRC 01/21/04: Added Section                                                     */
       /* Data Contraint Section.  Remove Rcords for Bad Type, Length, etc                */
       /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
       -- Trim extract spaces from results
       UPDATE NCI_LABS
          SET result = trim(result)
        WHERE LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' Results trimmed.');
       
       -- Trim extract spaces from units
       UPDATE NCI_LABS
          SET UNIT = trim(UNIT)
        WHERE LOAD_FLAG ='N';

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' Units trimmed.');
       
       -- Mark Records as Rejected where Results is Greater than 20 characters
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'RESULT has length greater than 20 characters.'
        WHERE Length(result) > 20 AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "RESULT has length greater than 20 characters."');
       
       -- Mark Records as Rejected where Normal Value > 30;
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'NORMAL_VALUE to Long (> 30)'
        WHERE Length(NORMAL_VALUE) > 30 AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "NORMAL_VALUE to Long (> 30)"');

       -- Ensure each record has a patient_position_id
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Patient not on-study'
        WHERE OC_PATIENT_POS IS NULL AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Patient not on-study"');


       crnt_ptid := '~';
       crnt_Study:= '~';
       U_Counter := 0; -- Count Bad PreStudy
       I_Counter := 0; -- Count Bad Off Study
       For I_Rec in (select distinct Patient_id, OC_Study, OC_Patient_Pos 
                       from nci_labs
                      where load_flag = 'N'
                      order by OC_Study, Patient_ID) LOOP
          BEGIN
       
             Log_Util.LogMessage('PLD - Processing Records for Study / patient / position: ' || 
                                  I_Rec.OC_Study ||' / '||I_REc.patient_id || ' / ' || I_Rec.OC_Patient_Pos);
           
             If crnt_Study <> I_Rec.OC_Study Then

                Log_Util.LogMessage('PLD - Study changed, getting Date Controls for study: ' || I_Rec.OC_Study);
                Begin
                   -- Get the study specific Date Check Options. If a particular option is blank,
                   -- then get the DEFAULT (STUDY='ALL') value for the option.
                   Select Nvl(a.DATE_CHECK_CODE, b.DATE_CHECK_CODE) DATE_CHECK_CODE, 
                          Nvl(a.OFF_STUDY_DCM, b.OFF_STUDY_DCM) OFF_STUDY_DCM, 
                          Nvl(a.OFF_STUDY_QUEST, b.OFF_STUDY_QUEST) OFF_STUDY_QUEST, 
                          Nvl(a.OFF_STUDY_OFFSET_DAYS, b.OFF_STUDY_OFFSET_DAYS) OFF_STUDY_OFFSET_DAYS, 
                          Nvl(a.PRESTUDY_LAB_DATE_DCM, b.PRESTUDY_LAB_DATE_DCM) PRESTUDY_LAB_DATE_DCM, 
                          Nvl(a.PRESTUDY_LAB_DATE_QUEST, b.PRESTUDY_LAB_DATE_QUEST) PRESTUDY_LAB_DATE_QUEST, 
                          Nvl(a.PRESTUDY_OFFSET_DAYS, b.PRESTUDY_OFFSET_DAYS) PRESTUDY_OFFSET_DAYS,
                          Nvl(a.BLANK_PRESTUDY_USE_ENROLL, b.BLANK_PRESTUDY_USE_ENROLL) BLANK_PRESTUDY_USE_ENROLL, 
                          Nvl(a.ENROLLMENT_DATE_DCM, b.ENROLLMENT_DATE_DCM) ENROLLMENT_DATE_DCM, 
                          Nvl(a.ENROLLMENT_DATE_QUEST, b.ENROLLMENT_DATE_QUEST) ENROLLMENT_DATE_QUEST
                     into v_date_check_code, 
                          v_offstudy_dcm, v_offstudy_quest, v_OffStudy_Offset,
                          v_Prestudy_Dcm, v_Prestudy_Quest, v_Prestudy_Offset,
                          v_blank_prestudy_use_enroll, v_enrollment_dcm, v_enrollment_quest
                     from NCI_LAB_LOAD_CTL a,
                          NCI_LAB_LOAD_CTL b
                    where a.OC_STUDY = I_Rec.OC_STUDY
                      and b.OC_STUDY = 'ALL';
                      
                Exception 
                   When NO_DATA_FOUND Then
                      Begin
                         -- Get the default Date Check Options.
                         Select DATE_CHECK_CODE,
                                OFF_STUDY_DCM,
                                OFF_STUDY_QUEST, 
                                OFF_STUDY_OFFSET_DAYS,
                                PRESTUDY_LAB_DATE_DCM,
                                PRESTUDY_LAB_DATE_QUEST,
                                PRESTUDY_OFFSET_DAYS,
                                BLANK_PRESTUDY_USE_ENROLL,
                                ENROLLMENT_DATE_DCM,
                                ENROLLMENT_DATE_QUEST
                           into v_date_check_code, 
                                v_offstudy_dcm, v_offstudy_quest, v_OffStudy_Offset,
                                v_Prestudy_Dcm, v_Prestudy_Quest, v_Prestudy_Offset,
                                v_blank_prestudy_use_enroll, v_enrollment_dcm, v_enrollment_quest
                           from NCI_LAB_LOAD_CTL a
                          where a.OC_STUDY = 'ALL';

                      Exception
                         When NO_DATA_FOUND Then
                            Log_Util.LogMessage('PLD - WARNING: No DEFAULT Study Controls');
                            v_OFFStudy_OffSet := 30;
                            v_blank_prestudy_use_enroll := 'N';
                      End;
                End;
                -- Write to the log, the values found
                Log_Util.LogMessage('PLD - Date Control Values for Study: "'|| I_Rec.OC_STUDY );
                Log_Util.LogMessage('      '||
                                    'Date_Check="'      ||v_date_check_code||'";  '||
                                    'OffStudy DCM="'    ||v_offstudy_dcm||'";  '||
                                    'OffStudy Quest="'  ||v_offstudy_quest||'";  '||
                                    'OffStudy OffSet="' ||to_char(v_OffStudy_OffSet)||'";  '||
                                    'PreStudy DCM="'    ||v_Prestudy_dcm||'";  '||
                                    'PreStudy Quest="'  ||v_Prestudy_quest||'";  '||
                                    'PreStudy OffSet="' ||to_char(v_PreStudy_OffSet)||'";  '||
                                    'Blank Use Enroll="'||v_blank_prestudy_use_enroll||'";  '||
                                    'Enrollment DCM="'  ||v_Enrollment_dcm||'";  '||
                                    'Enrollment Quest="'||v_Enrollment_quest||'".');
                
                -- set the current study value
                crnt_Study := I_Rec.OC_Study; 
             End If;                                                                        
                       
          EXCEPTION
             when others then
                Log_Util.LogMessage('PLD - WARNING: Unexpected ERROR Occurred.');
                Log_Util.LogMessage('PLD - RPED - Error Encountered: ' || SQLCODE);
                Log_Util.LogMessage('PLD - RPED - Error Message: ' || SQLERRM);
          END;

          prestudy_lab_date := NULL; -- The default value
                
          If v_date_check_code = 'NONE' Then
             Log_Util.LogMessage('PLD - No Date Check Performed (DATE_CHECK_CODE = "NONE").'); --prc 08/09/06
             Null; -- DO NOTHING, LET THE RECORD PASS THROUGH
          End If;
          If v_date_check_code in ('BOTH','PRE') Then
             -- Get Pre Study Lab Date.
             Get_Response(I_Rec.OC_Study, I_Rec.oc_patient_pos, 
                         v_PreStudy_DCM, v_PreStudy_Quest, v_result, v_found);

             If not v_found Then
                If v_blank_prestudy_use_enroll = 'Y' Then
                   Log_Util.LogMessage('PLD - Prestudy date not found, using registration date.');
                   -- Use Enrollment Date for PreStudy Lab Date
                   Get_Response(I_Rec.OC_Study, I_Rec.oc_patient_pos, 
                               v_Enrollment_DCM, v_Enrollment_Quest, v_result, v_found);
                   If not v_found Then
                      Log_Util.LogMessage('PLD - No Enrollment Date found, setting Blank.');
                   Else
                      prestudy_lab_Date := text2date(v_result);
                   End If;
                End If;
             Else
                prestudy_lab_Date := text2date(v_result);
             End If;
          End If;
          If v_date_check_code in ('BOTH','OFF') Then
             -- Get Pre Study Lab Date.
             Get_Response(I_Rec.OC_Study, I_Rec.oc_patient_pos, 
                         v_OffStudy_DCM, v_OffStudy_Quest, v_result, v_found);

             If not v_found Then
                Log_Util.LogMessage('PLD - Off Study Date not Found, using end of time.');
                OffStudy_date := to_date(3000000, 'J');
             Else
                 OffStudy_date := text2date(v_result);
             End If;
          End If;          

          If v_date_check_code = 'NONE' Then
             Null; -- DO NOTHING, LET THE RECORD PASS THROUGH
          End If;
          If v_date_check_code in ('BOTH','PRE') Then
             If prestudy_lab_date is null Then
                -- Mark Lab Records as Errors, where PresStudy Date is null
                update nci_labs
                   set load_flag = 'E',
                       Error_Reason = 'PreStudy Lab Date is NULL.'
                 where load_flag in ('N')
                   and OC_Patient_Pos = I_Rec.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
                   and OC_Study   = I_rec.OC_Study;

                U_Counter := U_Counter + SQL%RowCount;
                Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                                    ' records rejected because PreStudy Lab Date is NULL');
             Else
                -- Mark Lab Records as Errors, where Lab Sample Date is Less Than PresStudy Date.
                update nci_labs
                   set load_flag = 'E',
                       Error_Reason = 'Lab Sample Date is less than PreStudy Lab Date + Offset'
                 where to_date(substr(SAMPLE_DATETIME,1,6), 'mmddRR') < prestudy_lab_date + v_PreStudy_Offset
                   and load_flag = 'N'
                   and OC_Patient_Pos = I_Rec.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
                   and OC_Study   = I_rec.OC_Study;

                U_Counter := U_Counter + SQL%RowCount;
                Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                                    ' records rejected because Lab Sample Date is less than PreStudy Lab Date (' || prestudy_lab_date||') + Offset "'||v_Prestudy_offset||'".');
             End If;
          End If;
          If v_date_check_code in ('BOTH','OFF') Then
             -- Mark Lab Records as Errors, where Lab Sample Date is more than 30 days after Study Date
             update nci_labs
                set load_flag = 'E',
                    Error_Reason = 'Lab Sample Date is more than '||
                                    crnt_OFF_OffSet_Days|| ' days after Off Study Date'
              where to_date(substr(SAMPLE_DATETIME,1,6), 'mmddRR') > OffStudy_Date + v_OffStudy_OffSet
                and load_flag = 'N'
                   and OC_Patient_Pos = I_Rec.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
                and OC_Study   = I_rec.OC_Study;

             I_Counter := I_Counter + SQL%RowCount;
             Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||
                                 ' records rejected because Lab Sample Date is more than '||
                                 crnt_OFF_OffSet_Days|| ' days after Off Study Date(' || OffStudy_Date||')');

          End If;          

       End loop;   
       Log_Util.LogMessage('PLD - '||to_char(U_Counter)||' Total rows marked with Error for "Lab Sample Date is less than PreStudy Lab Date + Offset"');
       Log_Util.LogMessage('PLD - '||to_char(I_Counter)||' Total rows marked with Error for "Lab Sample Date is more than the specified days after Off Study Date"');

       -- Set error condition for a lab defined to be in more than one place (either DCM or Visit) in a study.
       -- Even with NEW LAB TEST LOOKUP, this should still work fine.
       I_Counter := 0;       
       
       -- prc 12/01/04 : Modified for loop to only execute if it really has to.                 
       For Dup_Lab in (SELECT distinct V.STUDY, M.test_component_id,
                                     M.laboratory, V.DEFAULT_VALUE_TEXT
                                FROM nci_lab_mapping   m
                                    ,duplicate_lab_mappings v
                                    ,nci_labs N
                               WHERE V.DEFAULT_VALUE_TEXT = M.OC_LAB_QUESTION
                                 and m.test_component_id  = N.test_component_id
                                 and M.laboratory         = decode(N.laboratory,'DUPE','CDW')
                                 and n.oc_study           = v.study
                                 and N.load_flag in ('N')                   ) Loop -- prc 11/30 added load_flag
       
           Update NCI_LABS N
              SET LOAD_FLAG    = 'E'
                 ,ERROR_REASON = 'Lab found in more than one DCM/Visit'
            WHERE load_flag in ('N')
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
       /* PRC 01/23/06: Add new way of mapping.  Some studies send data with C3D Questions identified.
       */
       -- Map C3D Question Name using LabTest_Name for Studies distinctly identified "YES"
       Update nci_labs a
          set OC_LAB_QUESTION = Substr(LABTEST_NAME,1,20)
        where Load_flag = 'N'
          and exists (select 'X' from nci_lab_load_ctl b
                       where b.oc_study = a.oc_study
                         and b.LABTESTNAME_IS_OCLABQUEST = 'Y');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_QUESTION" '||
                                  'for studies specifically identified to use "LABTEST_NAME"');

       -- Map C3D Question Name using LabTest_NameUpdate for Studies distinctly identified "NO"
       UPDATE NCI_LABS A
          SET (OC_LAB_QUESTION) = FIND_LAB_QUESTION(A.test_component_id, A.laboratory)
        WHERE load_flag in ('N')
          and exists (select 'X' from nci_lab_load_ctl b
                       where b.oc_study = A.oc_study
                         and b.LABTESTNAME_IS_OCLABQUEST = 'N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_QUESTION" '||
                                  'for studies specifically identified to use "FIND_LAB_QUESTION"');
                                  
       -- Map C3D Question Name using LabTest_Name for Studies defaulted to "YES"
       Update nci_labs a
          set OC_LAB_QUESTION = Substr(LABTEST_NAME,1,20)
        where Load_flag = 'N'
          and exists (select 'X' from nci_lab_load_ctl b
                       where b.oc_study = 'ALL'
                         and b.LABTESTNAME_IS_OCLABQUEST = 'Y')
          and not exists (select 'X' from nci_lab_load_ctl b   -- these were processed above
                          where b.oc_study = a.oc_study       -- don't redo them.
                            and b.LABTESTNAME_IS_OCLABQUEST IN ('N','Y'));

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_QUESTION" '||
                                  'for studies defaulted to use "LABTEST_NAME"');

       -- Map C3D Question Name using LabTest_Name for Studies defaulted to "NO"
       Update nci_labs a
          set OC_LAB_QUESTION = FIND_LAB_QUESTION(A.test_component_id, A.laboratory)
        where Load_flag = 'N'
          and exists (select 'X' from nci_lab_load_ctl b
                       where b.oc_study = 'ALL'
                         and b.LABTESTNAME_IS_OCLABQUEST = 'N')
          and not exists (select 'X' from nci_lab_load_ctl b   -- these were processed above
                          where b.oc_study = a.oc_study       -- don't redo them.
                            and b.LABTESTNAME_IS_OCLABQUEST IN ('N','Y'));

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_QUESTION" '||
                                  'for studies defaulted to use "FIND_LAB_QUESTION"');
       /*
       */

       -- PRC 12/16/04: Check to make sure Mapped Question is a valid OC Question
       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Mapped OC_LAB_QUESTION not a valid OC Question'
        WHERE load_flag in ('N') 
          and OC_LAB_QUESTION IS not NULL
          and not exists (select 'X' from labtests where
                           name = n.OC_LAB_QUESTION);

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error '||
                           '"Mapped OC_LAB_QUESTION not a valid OC Question".');

       -- Set error for test_component_id have 2 questions
       -- PRC 07/02/03:  There may be more than one oc_question per test_component_id
       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Lab Test Component ID (' || test_component_id ||
                             ') is double-mapped'
        WHERE load_flag in ('N') 
          and Cnt_Lab_Test_Maps(n.test_component_id,n.laboratory) > 1;

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test Component ID ( xxx ) is double-mapped".');

       -- PRC 12/20/2004: New; Populates indexed table to greatly increase speed of 
       -- DCM, EVENT, SUBSET assignment.
       
       Log_Util.LogMessage('PLD - Calling Populate_LABDCM_EVENTS_Table.');

       Populate_LABDCM_EVENTS_Table; 

       -- Found that under some conditions, a question could appear on more than one DCM, Event, Subset
       -- so we now mark those records as errors, and should have the DCMs fixed.
       -- New Routine uses NCI_STUDY_LABDCM_EVENTS_TB table for much faster response.
       update nci_labs n
          set load_flag = 'E' , error_reason = 'OC_Lab_Question on more than one Panel'
       where exists (SELECT 'X' 
                       FROM  NCI_STUDY_LABDCM_EVENTS_TB B
                      WHERE b.study = n.oc_study
                        and b.oc_lab_question = n.oc_lab_question
                        and b.oc_lab_question is not null
                        and display_sn = (select min(display_sn)
                                            from  NCI_STUDY_LABDCM_EVENTS_TB a
                                           where a.study = b.study
                                             and a.dcm_name = b.dcm_NAME
                                             and a.subset_name = b.subset_name
                                             and a.question_name = b.question_name
                                             and a.repeat_sn = b.repeat_sn
                                             and a.oc_lab_question = b.oc_lab_question)
                      having count(*) > 1)      
       and load_flag in ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "OC_Lab_Question on more than one Panel".');

       -- Determine the DCM, Subset and Clinical Planned Event for each mapped lab result
       -- may want to convert NCI_STUDY_DCMS_EVENTS_vw to a table for SPEED
       -- Version #2, Made Table out of NCI_STUDY_DCMS_EVENTS_VW with Lab Specific Questions Only,
       -- using NEW view NCI_STUDY_LABDCM_EVENTS_VW.
       -- Placed strategic indexes on the table to increase the speed of this step by light years.
       UPDATE NCI_LABS N
          SET (OC_LAB_PANEL, OC_LAB_EVENT, OC_LAB_SUBSET) = 
                      (SELECT dcm_name, cpe_name, subset_name
                         FROM  NCI_STUDY_LABDCM_EVENTS_TB B
                        WHERE b.study = n.oc_study
                          and b.oc_lab_question = n.oc_lab_question
                          and b.oc_lab_question is not null
                          and b.display_sn = (select min(display_sn)
                                                from  NCI_STUDY_LABDCM_EVENTS_TB a
                                               where a.oc_study = b.oc_study
                                                 and a.dcm_name = b.dcm_NAME
                                                 and a.subset_name = b.subset_name
                                                 and a.question_name = b.question_name
                                                 and a.repeat_sn = b.repeat_sn
                                                 and a.oc_lab_question = b.oc_lab_question))
        WHERE load_flag in ('N');
       
       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows successfully updated "OC_LAB_PANEL", "OC_LAB_EVENT", "OC_LAB_SUBSET".');

       -- Process "Other Lab Records"
       Process_Lab_Other;
       
       -- Check for Reject Records and specify Error Message

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Test is unmapped'
        WHERE OC_LAB_QUESTION IS NULL AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test is unmapped".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Test is invalid'
        WHERE UPPER(LABTEST_NAME) IN
              (SELECT UPPER(LABTEST_NAME) FROM NCI_INVALID_LABTESTS) AND
              LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Test is invalid".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Result is null'
        WHERE RESULT IS NULL AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Result is null".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Lab Result is invalid'
        WHERE UPPER(RESULT) IN
              (SELECT UPPER(RESULT_VALUE) FROM NCI_INVALID_RESULTS) AND
              LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Lab Result is invalid".');

       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Sample date is invalid'
        WHERE to_number(substr(sample_datetime, 7, 2)) > 23 AND
              LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Sample date is invalid".');

       -- prc 08/17/2004 : Added explicit test for NULL Sample Date/Time
       UPDATE NCI_LABS
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Sample Date/Time is Null'
        WHERE sample_datetime is null
          AND LOAD_FLAG IN ('N');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Sample Date/Time is Null".');

       UPDATE NCI_LABS N
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'Invalid OC question used in mapping'
        WHERE LOAD_FLAG IN ('N') AND OC_LAB_QUESTION IS NOT NULL AND
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
        WHERE LOAD_FLAG IN ('N') 
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
        WHERE LOAD_FLAG IN ('N') 
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

       -- PRC 08/23/2005: Added error check DCI Book Not Active
       update nci_labs N
          set load_flag    = 'E',
              error_reason = 'No Active DCI BOOK for Study'
        where load_flag = 'N'
          and not exists (
              SELECT distinct d.name, d.dcm_id, d.subset_name, dc.name
                FROM DCMS d, DCI_MODULES dm, DCIS dc, clinical_studies c,
                     dci_book_pages bp, dci_books b 
               WHERE d.name = n.oc_lab_panel
                 and d.subset_name = n.oc_lab_subset
                 and d.clinical_study_id = c.clinical_study_id
                 and d.dcm_subset_sn = dm.dcm_subset_sn 
                 and c.study = n.oc_study
                 and d.dcm_id = dm.dcm_id 
                 and dm.dci_id = dc.dci_id
                 AND dc.dci_id = bp.dci_id
                 AND b.dci_book_id = bp.dci_book_id
                 AND dc.dci_status_code = 'A' 
                 and b.DCI_BOOK_STATUS_CODE = 'A');

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "DCI requires time".');

       -- apply preferred translation of laboratory specific unit of measure
       UPDATE NCI_LABS N
          SET UNIT = (SELECT U.PREFERRED
                        FROM NCI_UOM_MAPPING U
                       WHERE UPPER(N.UNIT) = UPPER(U.SOURCE)
                         and UPPER(N.LABORATORY) = UPPER(U.LABORATORY))
        WHERE LOAD_FLAG IN ('N') 
          AND exists (select 'X' FROM NCI_UOM_MAPPING U
                       WHERE UPPER(N.UNIT) = UPPER(U.SOURCE)
                         and UPPER(N.LABORATORY) = UPPER(U.LABORATORY));

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' UOMs updated with preferred values..');

       -- validate the unit of measure
       UPDATE NCI_LABS N
          SET LOAD_FLAG = 'E', ERROR_REASON = 'Invalid Unit of Measure'
        WHERE LOAD_FLAG IN ('N') 
          AND N.UNIT IS NOT NULL 
          AND N.UNIT != ' ' 
          AND NOT EXISTS (SELECT U.VALUE
                            FROM NCI_UOMS U
                           WHERE N.UNIT = U.VALUE); -- Removed "UPPER" function.  They must exactly match.

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "Invalid Unit of Measure".');

       /* This code added to catch those Sampe Date/Time updates that would cause an NEW record    */
       /* because the DCI Date/Time is null, or doesn't match DCM Date/Time                        */
       /* A Key Change in OPA will cause DCI Time to NULL, Batch Data Load then mistakenly creates */
       /* a new received DCI and DCM to be created, and loads the data to the new record.          */
       /*
       /* PRC: 06/06/06: Removed this error check, because update records now include SubEvent Number,
       /*                which cause BDL not to look it up, which cause an error when DCI Time<> DCM Time
       /**/
       /* UPDATE NCI_LABS N 
          SET LOAD_FLAG    = 'E'
             ,ERROR_REASON = 'DCI Date/Time doesn''t match DCM Date/Time.'
        WHERE LOAD_FLAG IN ('N') 
          AND exists (Select a.CLIN_PLAN_EVE_NAME, a.SN, a.SUBEVENT_NUMBER, a.VISIT_NUMBER, 
                             a.dcm_date, a.dcm_time, c.dci_date, c.dci_time  
                        from received_dcms a,
                             dcms b,
                             received_dcis c,
                             clinical_studies s
                       where a.dcm_id = b.dcm_id
                         and a.RECEIVED_DCI_ID = c.RECEIVED_DCI_ID
                         and a.DCM_SUBSET_SN = b.DCM_SUBSET_SN  
                         and a.DCM_layout_SN = b.DCM_layout_SN  
                         and b.subset_name = N.oc_lab_subset    
                         and a.patient = N.oc_patient_pos
                         and a.clinical_study_id = s.Clinical_study_id
                         and s.study = n.oc_study
                         and b.name = N.oc_lab_panel
                         and substr(dcm_date,5,2)||substr(dcm_date,7,2)||substr(dcm_date,3,2)||
                             substr(nvl(dcm_time,'000000'),1,4) = N.sample_datetime
                         and a.END_TS = to_date(3000000, 'J')      
                         and c.END_TS = to_date(3000000, 'J')      
                         and (a.dcm_date <> nvl(c.dci_date,'0') or
                              a.dcm_time <> nvl(c.dci_time,'0')));

       Log_Util.LogMessage('PLD - '||to_char(SQL%RowCount)||' rows updated for error "DCI Date/Time doesn''t match DCM Date/Time."');
       */
       
       -- Identify duplicate records
       Log_Util.LogMessage('PLD ****** Starting Duplicate Records Check (identify_duplicate_records).');
       identify_duplicate_records;
       Log_Util.LogMessage('PLD ****** Finished Duplicate Records Check.');

       Commit; -- prc 07/14/03  Added commit statement
       
  /*   MOVED TO GET_PROCESS_LOAD_LABS : Records for Update should not be processed here.
       -- Identify Updates to Loaded Records.
       Log_Util.LogMessage('PLD - Begin "Identifying Load as Updates".');
       FindandMark_Updates;
       Log_Util.LogMessage('PLD - Finished "Identifying Load as Updates".');
          
       Commit;
  */   

       Log_Util.LogMessage('PLD - Finished "PROCESS_LAB_DATA".');
  END process_lab_data;

  Procedure LLI_Processing is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
  /* This section is used to mark New records with either LOAD or REVIEW status. */
  /* with the appropriate values for patient and study as well as marked with an */
  /* error flag when they don't meet each of the individual tests below.         */
  /* The types of errors include:                                                */
  /*    Patient found on more than one study                                     */
  /*    Patient not on-study                                                     */
  /*    Etc.                                                                     */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                       */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 01/06/05: Corrected "Bug" where the count of Archived and Previously  */
  /*                 loaded records was incorrect.                               */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     X_Cnt Number;
  
  Begin
     Log_Util.LogMessage('LLIP - Process Records for LLI Started.');
    
     Log_Util.LogMessage('LLIP - Checking for Updates to Previously Loaded Records.');

     -- Archive LabTests that were previously Archived
     Update nci_labs a
        set load_flag = 'A', LOAD_MARK_DATE = Sysdate, LOAD_MARK_USER = USER
      where Load_flag IN ('N','D','R') 
        and exists (select 'X' from nci_labs b
                     where b.oc_study   = a.oc_study 
                       and b.OC_Patient_Pos = a.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
                       and b.sample_datetime = a.sample_datetime
                       and b.labtest_name = a.labtest_name
                       and b.load_flag in ('A'));        

     Log_Util.LogMessage('LLIP - '||to_char(SQL%RowCount)||' records marked ARCHIVE because Lab Test previously Archived');

     -- Load LabTests that were previously Loaded
     Update nci_labs a
        set load_flag = 'L', error_reason = 'Auto Load because this is an update.'
      where Load_flag IN ('N','D','R') 
        and exists (select 'X' from nci_labs b
                     where b.oc_study   = a.oc_study 
                       and b.OC_Patient_Pos = a.OC_Patient_Pos -- 08/07/06: Use Pat_pos instead of ID
                       and b.sample_datetime = a.sample_datetime
                       and b.labtest_name = a.labtest_name
                       and b.load_flag in ('C','U'));        

     Log_Util.LogMessage('LLIP - '||to_char(SQL%RowCount)||' records marked for LOAD as they are UPDATES.');

     -- Update specific Studies for Review
     Update nci_labs a
        set load_flag = 'R'
      where Load_flag = 'N'
        and exists (select 'X' from nci_lab_load_ctl b
                    where a.oc_study = b.oc_study
                      and b.Review_study = 'Y');
  
     Log_Util.LogMessage('LLIP - '||to_char(SQL%RowCount)||' rows marked for REVIEW (Study is defined for Review)."');
  
     -- Update specific Studies for Load
     Update nci_labs a
        set load_flag = 'L', LOAD_MARK_DATE = Sysdate, LOAD_MARK_USER = USER
      where Load_flag = 'N'
        and exists (select 'X' from nci_lab_load_ctl b
                    where a.oc_study = b.oc_study
                      and b.Review_study = 'N');

     Log_Util.LogMessage('LLIP - '||to_char(SQL%RowCount)||' rows marked for LOAD (Study is defined for AutoLoad)."');
                          
     -- Update specific Studies for Review
     Update nci_labs a
        set load_flag = 'R'
      where Load_flag = 'N'
        and exists (select 'X' from nci_lab_load_ctl b
                    where b.oc_study = 'ALL'
                      and b.Review_study = 'Y');

     Log_Util.LogMessage('LLIP - '||to_char(SQL%RowCount)||' rows marked for REVIEW (Default defined)."');
  
     -- Update specific Studies for Load
     Update nci_labs a
        set load_flag = 'L', LOAD_MARK_DATE = Sysdate, LOAD_MARK_USER = USER
      where Load_flag = 'N'
        and exists (select 'X' from nci_lab_load_ctl b
                    where b.oc_study = 'ALL'
                      and b.Review_study = 'N');
  
     X_Cnt := SQL%RowCount;

     If X_Cnt > 0 Then
        Log_Util.LogMessage('LLIP - '||to_char(X_Cnt)||' rows marked for LOAD (Default defined)."');
     End If;                        

     -- Update Anything Left over with error
     -- This would mean that the study is not specifically set-up either way AND
     -- that the default record "ALL" is not set-up either way.
     Update nci_labs a
        set load_flag = 'E', Error_Reason = 'Can not identify "Review vs Load" for LLI. Contact Administrator.'
      where Load_flag = 'N';
  
     X_Cnt := SQL%RowCount;
 
     If X_Cnt > 0 Then
        Log_Util.LogMessage('LLIP - '||to_char(X_Cnt)||' rows marked with REVIEW/LOAD Error (Not defined)."');
     End If;
  
     Log_Util.LogMessage('LLIP - Process Records for LLI Finished. ');
  
  End LLI_Processing;

  Procedure Process_Batch_Load Is
     /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     /* This section is used to take the Records In NCI_LABS, and process then for  */
     /* Batch Loading.  This procedure was broken out of Process_Lab_Data.          */
     /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */ 
     
     labs_count number;
  
  BEGIN
      Log_Util.LogMessage('PBL - Beginning "PROCESS_BATCH_LOAD" (PBL).');

     -- check if there enough 'N' records to process, if so continue with loading lab results
      select count(*)
        into labs_count
        from BDL_TEMP_FILES;

      if (labs_count > 0) then
         Log_Util.LogMessage('PBL - There are '||to_char(labs_count)||' records in "BDL_TEMP_FILES" to process for Batch Loading.');

         Log_Util.LogMessage('PBL - Executing "automate_bdl.create_dat_file".');
         automate_bdl.create_dat_file;

         Log_Util.LogMessage('PBL - Finished "automate_bdl.create_dat_file".');

         Log_Util.LogMessage('PBL - Calling Insert Missing DCMs.');

         insert_lab_data.insert_missing_DCMs;

         select count(*)
           into labs_count
           from BDL_TEMP_FILES;
         if (labs_count > 0) then
         
            Log_Util.LogMessage('PBL - Executing "automate_bdl.create_dat_file".');
            automate_bdl.create_dat_file;
 
            Log_Util.LogMessage('PBL - Finished "automate_bdl.create_dat_file".');
         End If;
      Else
      
         Log_Util.LogMessage('PBL - There are NO RECORDS in "BDL_TEMP_FILES" to process for Batch Loading.');
      
      end if;
      Log_Util.LogMessage('PBL - Purging LABLOAD Logs < SYSDATE-14.');
      MessageLogPurge('LABLOAD%',SYSDATE - 14);
      Log_Util.LogMessage('PBL - Finished "PROCESS_BATCH_LOAD" (PBL).');
  END;  

END cdw_data_transfer_v3;
/

sho  error

