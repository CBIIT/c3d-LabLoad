CREATE OR REPLACE PACKAGE BTRIS_DATA_TRANSFER AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
  /*       Date: 11/17/11                                                              */
  /*Description: This process will get lab data from the external BTRIS Data Feed      */
  /*             and process the data prior to loading the lab data into Oracle        */
  /*             Clinical.  It DOES NOT load data to Oracle Clinical (C3D), but rather */
  /*             places it into the processing table for the Lab Loader.               */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  -- Global Package Variables.

  Labs_Count      Number;

  Function PULL_LABS_FROM_FILE Return Number;
  Function PULL_NEW_LABS Return Number;
  Procedure PUSH_LABS_TO_LOADER;
  Procedure PULL_AND_PUSH_LABS(v_logName in Varchar2 Default NULL);
  Procedure Submit_PULL_AND_PUSH_LABS(JobNumber IN OUT NUMBER, v_logName IN OUT VARCHAR2);


  Function Text2Date(v_text in varchar2) return date;
  Function Date2NCIDate(v_Date in DATE) return Varchar2;

END BTRIS_DATA_TRANSFER;
/


CREATE OR REPLACE PACKAGE BODY BTRIS_DATA_TRANSFER AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
  /*       Date: 11/17/11                                                              */
  /*Description: This process will get lab data from the external BTRIS Data Feed      */
  /*             and process the data prior to loading the lab data into Oracle        */
  /*             Clinical.  It DOES NOT load data to Oracle Clinical (C3D), but rather */
  /*             places it into the processing table for the Lab Loader.               */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  Function Text2Date(v_text in varchar2) return date is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This function is used to convert TEXT Dates to Oracle Dates           */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

     v_hold_text varchar2(30);
     v_hold_date date := Null;
  Begin
     v_hold_text := v_text;
     If instr(v_hold_text,'.') > 0 Then
        v_hold_text := Substr(v_hold_text,1,(instr(v_hold_text,'.')-1));
     End If;

     v_hold_date := to_date(v_hold_text, 'YYYY-MM-DD HH24:MI:SS');

     return v_hold_date;
  Exception
     when others then
        Log_Util.LogMessage('TEXT2DATE ERROR: Unexpected ERROR Occurred in TEXT2DATE('||v_text||').');
        Log_Util.LogMessage('TEXT2DATE ERROR: Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('TEXT2DATE ERROR: Error Message: ' || SQLERRM);
        return NULL;
  End;

  Function Date2NCIDate(v_Date in DATE) return Varchar2 is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This function is converts a Date to a NCI Lab Loader Text Date        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

     v_hold_date date := Null;
     v_hold_text varchar2(30);
  Begin
     v_hold_date := v_date;

     v_hold_text := to_char(v_hold_date, 'MMDDYYHH24MI');

     return v_hold_text;
  Exception
     when others then
        Log_Util.LogMessage('DATE2NCIDATE ERROR: Unexpected ERROR Occurred in DATE2NCIDATE.');
        Log_Util.LogMessage('DATE2NCIDATE ERROR: Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('DATE2NCIDATE ERROR: Error Message: ' || SQLERRM);
        return NULL;
  End;

  Procedure Recheck_Unmapped_Labs(P_Method in Varchar2 Default 'HELP') is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This procedure is used to identify labs records that were  not loaded */
  /*             due to the 'Lab Test is unmapped' error.  These labs are examined to  */
  /*             determine if they are now mapped. There are 2 options for this        */
  /*             procedure.  MARK - Marks the records as 'NEW' and resets the field    */
  /*             ERROR_REASON.  These records will then wait for the next batch of Lab */
  /*             Loading to take place, and be included.  PROCESS - Performs the MARK  */
  /*             function, but will process the records immediately.                   */
  /*-----------------------------------------------------------------------------------*/
  /* Modification History:                                                             */
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
           For Xrec in (SELECT count(*) Rec_Count, N.OC_STUDY, N.TEST_COMPONENT_ID, N.LABORATORY
                         FROM nci_labs n
                        WHERE load_flag = 'E'
                          AND ERROR_REASON = 'Lab Test is unmapped'
                        Group by N.OC_STUDY, N.Test_Component_id, n.laboratory) Loop

              -- Find the OC Question for the Study, PASS Study to find Map Version
              v_oc_lab_question := cdw_data_transfer_v3.FIND_LAB_QUESTION(XRec.OC_STUDY, Xrec.test_component_id, XRec.laboratory);

              If v_oc_Lab_Question is not null Then
                 -- Report that the Lab Test can be mapped.
                 Log_Util.LogMessage('RCKUMP - Study: "'||Xrec.OC_Study||'"  Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
                                     ' can be mapped to: "'|| V_OC_LAB_QUESTION ||'"  - Records Needing Update: '||
                                      to_char(Xrec.Rec_Count));

                 If Upper(P_Method) in ('MARK','PROCESS') Then
                    -- Mark the Records for the Study / Lab Test that were found for re-processing
                    Update NCI_LABS n
                       Set Load_flag    = 'N'
                          ,Error_Reason = 'Reloaded due to: ' || Error_Reason
                     where oc_study = XRec.OC_Study
                       and load_flag = 'E'
                       and error_Reason = 'Lab Test is unmapped'
                       and n.test_component_id = Xrec.TEST_COMPONENT_ID
                       and n.laboratory = XRec.Laboratory;

                   Log_Util.LogMessage('RCKUMP - '||to_char(SQL%RowCount)||' rows successfully marked for reprocessing.');

                   Commit;

                 End If;

              Else
                 -- Report those Lab Tests that are still not mapped.
                 Log_Util.LogMessage('RCKUMP - Study: "'||Xrec.OC_Study||'"  Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
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

          --Get_Process_Load_labs('WAITING');

       End If;

     End If;

     Log_Util.LogMessage('RCKUMP - Recheck Unmapped Labs Finished.');

  End; -- Reload_Error_Labs


  Procedure PULL_AND_PUSH_LABS(v_logName in Varchar2 Default NULL) is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This Procedure is used to call the PULL_New_Labs function and then the*/
  /*             PUSH_LABS_TO_LOADER procedure.  It allows for the LogName to be set at*/
  /*             the time of execution.
  /*-----------------------------------------------------------------------------------*/
  /* Modification History:                                                             */
  /*-----------------------------------------------------------------------------------*/

    v_NewRecs  Number := 0;
    v_LabRecs  Number := 0;

  Begin
     If v_logName is null Then
        Log_Util.LogSetName('BTRIS_PULLPUSH_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
     Else
        Log_Util.LogSetName(v_logname,'LABLOAD');
     End If;
     Log_Util.LogMessage('PAPL - Starting "BTRIS_DATA_TRANSFER.PULL_AND_PUSH_LABS".');
     If v_logName is not null Then
        Log_Util.LogMessage('PAPL - LogName = "' || v_logname ||'".');
     End If;

     Log_Util.LogMessage('PAPL - Calling PULL_NEW_LABS.');
     v_NewRecs := PULL_NEW_LABS;

     Log_Util.LogMessage('PAPL - Calling PUSH_LABS_TO_LOADER.');
     PUSH_LABS_TO_LOADER;

     Log_Util.LogMessage('PAPL - Finished "BTRIS_DATA_TRANSFER.PULL_AND_PUSH_LABS".');

  End;

  Procedure  Submit_PULL_AND_PUSH_LABS(JobNumber IN OUT NUMBER, v_logName IN OUT Varchar2) is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This Procedure is used to SUBMIT as an Oracle Batch Job, the          */
  /*             PULL_AND_PUSH_LABS procedure.
  /*-----------------------------------------------------------------------------------*/
  /* Modification History:                                                             */
  /*-----------------------------------------------------------------------------------*/

  h_logName  VarChar2(30);
  --JobNumber Number;
  JobText    VarChar2(200);

  Begin
     If v_logName is null Then
        v_logName := 'BTRIS_PULLPUSH_' || to_char(sysdate, 'YYYYMMDD-HH24MI');
     End If;

     JobText := 'Begin BTRIS_DATA_TRANSFER.PULL_AND_PUSH_LABS('''||v_logName||'''); End;';

     dbms_job.submit(job=>JobNumber,
                     what=>JobText,
                     next_date=>sysdate,
                     interval=>NULL);

  End;

  Function PULL_LABS_FROM_FILE Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This function is used to pull records from the BTRIS Raw Lab FILE     */
  /*             and places them into the BTRIS Raw Data Table, then pulls records from*/
  /*             the BTRIS Raw Data Table to the BTRIS Lab Result table in  preparation*/
  /*             for loading to Oracle Clinical C3D.  The function only pulls those    */
  /*             records that have not been pulled before, based on OBSERVATION GUID.  */
  /*             'NEW' records are assigned a LOAD_FLAG of "N".  Function returns the  */
  /*             count of NEW records.                                                 */
  /*-----------------------------------------------------------------------------------*/
  /* Modification History:                                                             */
  /*-----------------------------------------------------------------------------------*/

     v_rcount  number := 0;

  BEGIN
      If Log_Util.Log$LogName is null Then
         Log_Util.LogSetName('BTRIS_FILE_PULL_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
      End If;

     Log_Util.LogMessage('PLFF - Beginning "BTRIS_DATA_TRANSFER.PULL_LABS_FROM_FILE".');

     --Log_Util.LogMessage('PLFF - Starting "BTRIS_LOAD_LAB_FTPDATE.LOAD_FLAT_FILE"');
     --BTRIS_LOAD_LAB_FTPDATE.LOAD_FLAT_FILE;
     --Log_Util.LogMessage('PLFF - Finished "BTRIS_LOAD_LAB_FTPDATE.LOAD_FLAT_FILE"');
     Log_Util.LogMessage('PLFF - NOT IMPLEMENTED');
     Log_Util.LogMessage('PLFF - NOT IMPLEMENTED');
     Log_Util.LogMessage('PLFF - NOT IMPLEMENTED');
     --Log_Util.LogMessage('PLFF - Starting "BTRIS_DATA_TRANSFER.PULL_MISSED_LABS"');
     v_rcount := PULL_NEW_LABS;
     Log_Util.LogMessage('PLFF - Finished "BTRIS_DATA_TRANSFER.PULL_LABS_FROM_FILE"');

     Return v_Rcount;

  END PULL_LABS_FROM_FILE;

  Function PULL_NEW_LABS Return Number IS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*Description: This function is used to pull records from the BTRIS Raw Lab FILE     */
  /*             and place them into the BTRIS Lab Results Table in  preparation for   */
  /*             loading to Oracle Clinical C3D.  The function only pulls those records*/
  /*             that have not been pulled before, based on OBSERVATION GUID.          */
  /*             'NEW' records are assigned a STATUS_FLAG of "N".  Function returns the*/
  /*             count of NEW records.                                                 */
  /*-----------------------------------------------------------------------------------*/
  /* Modification History: Modified to use looping                                     */
  /*-----------------------------------------------------------------------------------*/

  v_rcount  number := 0;

  BEGIN
     Begin
        If Log_Util.Log$LogName is null Then
           Log_Util.LogSetName('BTRIS_TABLE_PULL_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
        End If;
        Log_Util.LogMessage('PNL2 - Starting BTRIS_DATA_TRANSFER.PULL_NEW_LABS');
        Log_Util.LogMessage('PNL2 - Starting INSERT Loop');

        --OPEN c_data;
	LOOP
           --Log_Util.LogMessage('PNL - Fetching 10000 Records.');
	   INSERT INTO BTRIS_LAB_RESULTS
           select BTRIS_EVENT_ID,
	                  BTRIS_OBSERVATION_ID,
	                  BTRIS_LAB_TEST_ID,
	                  LAB_TEST_NAME,
	                  LAB_RESULT,
	                  LAB_UNIT,
	                  LAB_RANGE,
	                  LAB_DATE_TXT,
	                  BTRIS_SUBJECT_ID,
	                  PATIENT_ID,
	                  LABTEST_CODE,
	                  BTRIS_CREATE_DATE,
	                  BTRIS_MODIFY_DATE,
	                  LAB_REPORT_DATE,
	                  EXTRACT_QUERY_DATE,
	                  EXTRACT_EXTRACT_DATE,
	                  sysdate,
	                  'N',
	                  NULL,
	                  NULL,
	                  NULL
	             from BTRIS_LAB_TEST_RESULTS a
	            where not exists (select 'X' from BTRIS_LAB_RESULTS c
	   	                    where a.BTRIS_OBSERVATION_ID = c.BTRIS_OBSERVATION_ID)
	   	      and rownum < 10000;

           EXIT WHEN SQL%ROWCOUNT = 0;
           v_rcount := v_rcount + SQL%Rowcount;

	   Log_Util.LogMessage('PNL2 - Inserted '||to_char(SQL%RowCount)||' running total '||to_char(v_rcount)||'.');

           Commit;

	END LOOP;

        Commit;
     END;

     Log_Util.LogMessage('PNL2 - '||to_char(v_rcount)||' rows inserted into "BTRIS_LAB_RESULTS" from "BTRIS_LAB_TEST_RESULTS".');

     Log_Util.LogMessage('PNL2 - Finished BTRIS_DATA_TRANSFER.PULL_NEW_LABS');

     Return v_Rcount;

  END PULL_NEW_LABS;

  PROCEDURE PUSH_LABS_TO_LOADER IS

     v_rcount  number := 0;
     l_error_count  NUMBER := 0;

     curr_pt    number(10);
     last_pt    number(10);
     lab_count  number(10);
     check_max  char(1);

  BEGIN
     last_pt   := null;
     curr_pt   := null;
     lab_count := 0;

     If Log_Util.Log$LogName is null Then
        Log_Util.LogSetName('BTRIS_PSH2LDR_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
     End If;
     Log_Util.LogMessage('PLTL - Starting "BTRIS_DATA_TRANSFER.PUSH_LABS_TO_LOADER".');

     Log_Util.LogMessage('PLTL - Check for invalid values.');
     begin

        Log_Util.LogMessage('PLTL - Checking LABTEST_VALUES');

        UPDATE BTRIS_LAB_RESULTS
           set STATUS_FLAG = 'E', STATUS_TEXT = 'Invalid LABTEST_CODE Value', STATUS_DATE = sysdate
         WHERE STATUS_FLAG = 'N'
           AND LABTEST_CODE in (SELECT VALUE From BTRIS_LAB_INVALID_VALUES
                                WHERE ATTRIBUTE = 'LABTEST_CODE');

        Log_Util.LogMessage('PLTL - '||to_char(SQL%RowCount)||' BTRIS_LAB_RESULTS records have invalid LABTEST_CODE values.');

     Exception
           when OTHERS then
             Log_Util.LogMessage('PLTL - Unexepected error during Check LABTEST_VALUES in BTRIS_DATA_TRANSFER.PUSH_LABS_TO_LOADER.');
             Log_Util.LogMessage('PLTL - Error Encountered: ' || SQLCODE);
             Log_Util.LogMessage('PLTL - Error Message: ' || SQLERRM);
     End;

     Begin
        LOOP
           Insert into NCI_LABS (
                  PATIENT_ID,
                  SAMPLE_DATETIME,
                  TEST_COMPONENT_ID,
                  LABORATORY,
                  LABTEST_NAME,
                  RESULT,
                  UNIT,
                  NORMAL_VALUE,
                  RECEIVED_DATE,
                  TEST_CODE,
                  CDW_RESULT_ID)
           SELECT PATIENT_ID,
	          Date2NCIDate(Text2Date(LAB_DATE_TXT)),
	          BTRIS_LAB_TEST_ID,
                  'BTRIS' LABORATORY,
                  LAB_TEST_NAME,
                  substr(LAB_RESULT,1,200),
                  LAB_UNIT,
                  LAB_RANGE,
                  INSERT_DATE,
                  LABTEST_CODE,
   	          BTRIS_OBSERVATION_ID
             FROM BTRIS_LAB_RESULTS a
            WHERE STATUS_FLAG = 'N'
              AND not exists (select 'X' from NCI_LABS c
   	                       where c.CDW_RESULT_ID = a.BTRIS_OBSERVATION_ID)
   	      and rownum < 10000;

           EXIT WHEN SQL%ROWCOUNT = 0;
           v_rcount := v_rcount + SQL%Rowcount;

	   Log_Util.LogMessage('PLTL - Inserted '||to_char(SQL%RowCount)||' running total '||to_char(v_rcount)||'.');

           Commit;

        END LOOP;

        Commit;

        Log_Util.LogMessage('PLTL - '|| to_char(v_rcount)||' records inserted into "NCI_LABS" from "BTRIS_LAB_RESULTS".');

        begin
           UPDATE BTRIS_LAB_RESULTS a
              set STATUS_FLAG = 'C', STATUS_TEXT = 'Complete, moved to NCI_LABS.', load_date = sysdate, STATUS_DATE = sysdate
            WHERE STATUS_FLAG = 'N'
              and exists (select 'X' from NCI_LABS c
   	                   where c.CDW_RESULT_ID = a.BTRIS_OBSERVATION_ID);

           Log_Util.LogMessage('PLTL - '||to_char(SQL%RowCount)||' BTRIS_LAB_RESULTS records updated STATUS_FLAG to "C".');

        Exception
              when OTHERS then
                Log_Util.LogMessage('PLTL - Unexepected error during UPDATE in BTRIS_DATA_TRANSFER.PUSH_LABS_TO_LOADER.');
                Log_Util.LogMessage('PLTL - Error Encountered: ' || SQLCODE);
                Log_Util.LogMessage('PLTL - Error Message: ' || SQLERRM);
        End;


     Exception
           when OTHERS then
             Log_Util.LogMessage('PLTL - Unexepected error during INSERT in BTRIS_DATA_TRANSFER.PUSH_LABS_TO_LOADER.');
             Log_Util.LogMessage('PLTL - Error Encountered: ' || SQLCODE);
             Log_Util.LogMessage('PLTL - Error Message: ' || SQLERRM);
     End;


     COMMIT;

     Log_Util.LogMessage('PLTL - Finishing "PUSH_LABS_TO_LOADER".');

  END PUSH_LABS_TO_LOADER;


END BTRIS_DATA_TRANSFER;
/


