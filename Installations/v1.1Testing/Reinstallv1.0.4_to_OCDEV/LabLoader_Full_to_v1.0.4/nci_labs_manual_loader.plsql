CREATE OR REPLACE PACKAGE nci_labs_manual_loader AS

  SqlErrMsg varchar2(2000);

  Procedure AutoLoad (B_Id in Number);

  Procedure Submit_Batch (B_Id in Number);

  Procedure MassageHoldData (B_Id in Number, BStudy in Varchar);

  Procedure MassageStageData (B_Id in Number, BStudy in Varchar);

  Procedure MoveFromHoldToStage  (B_Id in Number, BStudy in Varchar);

  Procedure CopyFromStageToLoader (B_Id in Number, BStudy in Varchar, BLoad_Flag in Varchar);

  Procedure LoadToOC(BStudy in Varchar2, L_Type in Varchar2 Default 'NEW');

  Procedure AutoLoad_Watcher;

  Procedure AutoLoad_Watcher_Control (Method in Varchar2 default 'START');

  Procedure HoldForOC(BStudy in Varchar2);

END NCI_Labs_manual_loader;
/

sho  error


CREATE OR REPLACE PACKAGE BODY nci_labs_manual_loader AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad- Ekagra Software Technologies                          */
  /*       Date: 10/21/03                                                              */
  /*Description: Copied from original CDW_DATA_TRANSFER                                */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* PRC 06/21/2007: Added Exception Handlers where none existed.  Added/modified      */
  /*                 comments as needed.                                               */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  Procedure AutoLoad_Watcher_Control (Method in Varchar2 default 'START') is
     -- This routine is used to ensure that the AutoLoader Batch Procedure (Watcher) is
     -- executing.  There is only one action at the moment.  The detault action is "START"

     H_Job_Number Number;      -- Hold the Submitted Job Id
     Hold_Number Number;       -- Holds Job Id Number during checking
     Hold_Found  Varchar2(1);  -- Holds Found/Not-Found results

  Begin
     If Method = 'START' Then
        -- "START" the Lab Load Manual AutoLoad Watcher...
        Begin
           -- Check to see if the AUTOLOAD_WATCHER is already submitted.
           select 'X'
             into hold_Found
             from user_jobs
             where upper(what) like '%NCI_LABS_MANUAL_LOADER.AUTOLOAD_WATCHER%';

        Exception
           When Others Then
              -- Submit the WATCHER procedure for Batch Execution because it was not found
              -- with the above select statement..  Give it 5 second intervals
              dbms_job.submit(H_Job_Number,
                             'BEGIN NCI_LABS_MANUAL_LOADER.AUTOLOAD_WATCHER; END;',
                              sysdate,
                              'sysdate + 5/86400');

        End;
     End If;

  End;


  Procedure AutoLoad_Watcher is
     -- This procedure checks the Submitted Batches table for new Autoload Jobs.

     H_Job_Number Number;      -- Hold the Submitted Job Id
     Hold_Number Number;       -- Holds Job Id Number during checking
     Hold_Found  Varchar2(1);  -- Holds Found/Not-Found results

  Begin
     -- See if there are any batches of records that need processed.
     -- Submit the Batch_ID to Oracle Batch for processing.
     -- Records without a Job_Id need to be processed.
     For X in (select BATCH_ID
                 from NCI_LABS_MANUAL_LOAD_BATCHES
                where JOB_ID IS NULL) Loop

        Begin
           -- For each batch found in the table, submit a job to process them.
           dbms_job.submit(H_Job_Number,'Begin NCI_LABS_MANUAL_LOADER.Autoload('||to_char(X.Batch_ID)||'); End;');

           -- After submitting the job, update the JOB_ID for the Batch.  Signifies that the
           -- Batch is processed/being processed.
           Update NCI_LABS_MANUAL_LOAD_BATCHES
              set JOB_ID = H_Job_Number,
                  JOB_START_DATE = Sysdate,
                  BATCH_STATUS = 'S',
                  STATUS_COMMENT = 'Autoload Batch Job Submitted, #'||to_char(H_Job_Number)
            where BATCH_ID = X.Batch_id;

           Commit;
        Exception
           When Others then
              -- Log that there was an unknown/unexpected error.
	      Log_Util.LogMessage('ALW - ERROR: AutoLoad_Watcher - Batch Processing - Batch_ID "'||X.Batch_Id||'".');
	      Log_Util.LogMessage('ALW - ERROR: Error Encountered: ' || SQLCODE);
	      Log_Util.LogMessage('ALW - ERROR: Error Message: ' || SQLERRM);
        End;

     End Loop;

     For X in (select STUDY
                 from NCI_LABS_AUTOLOAD_HOLD ) Loop

        -- For each Study in Holding do the following

        Begin
           -- See if records for the study exists that are marked as holding
           -- load_flag = 'n'
           Select 'X'
             Into Hold_Found
             from dual
             where exists (select 'X' from NCI_LABS
            where OC_STUDY = X.STUDY
              and LOAD_FLAG = 'n');

           If Hold_Found = 'X' Then
              -- If there are records holding, update the restart count and date before
              -- submitting the study for processing.
              Update NCI_LABS_AUTOLOAD_HOLD
                 set Restart_Date = sysdate,
                     Restart_Count = nvl(Restart_Count,0) + 1
               where Study = X.Study;

              Commit;

              -- Load the study having holding records.
              NCI_LABS_MANUAL_LOADER.LoadToOC(X.Study, 'RELOAD');

           Else
              -- If there are no records holding for the study, remove the
              -- study from the processing table.  There is nothing to process.
              Delete from NCI_LABS_AUTOLOAD_HOLD
	       Where Study = X.Study;

	       Commit;

           End If;

        Exception
           When NO_DATA_FOUND Then
              Delete from NCI_LABS_AUTOLOAD_HOLD
               Where Study = X.Study;

              Commit;
           When Others then
              -- Log that there was an unknown/unexpected error.
	      Log_Util.LogMessage('ALW - ERROR: AutoLoad_Watcher - Hold Processing - Study "'||X.Study||'".');
	      Log_Util.LogMessage('ALW - ERROR: Error Encountered: ' || SQLCODE);
	      Log_Util.LogMessage('ALW - ERROR: Error Message: ' || SQLERRM);

        End;

        Commit;

     End Loop;

  End;


  Procedure Submit_Batch (B_Id in Number) is
     -- This procedure is used to Enter a Batch_ID into the AutoLoader Batches table.
  Begin
     -- Insert the Batch_ID into the table, only if it does not already
     -- exist in the table.
     Insert into NCI_LABS_MANUAL_LOAD_BATCHES
        (BATCH_ID, SUBMIT_BY, SUBMIT_DATE)
     select B_ID, USER, SYSDATE
       from DUAL
      where not exists (select 'X'
                         from NCI_LABS_MANUAL_LOAD_BATCHES
                        where BATCH_ID = B_ID);
  Exception
     When Others then
        -- Log that there was an unknown/unexpected error.
        Log_Util.LogMessage('SB - ERROR: Submit_Batch - Batch_ID "'||B_Id||'".');
        Log_Util.LogMessage('SB - ERROR: Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('SB - ERROR: Error Message: ' || SQLERRM);

  End;

  Procedure AutoLoad (B_Id in Number) is
     -- This procedure processes the Batch of records submitted for AutoLoading.  It uses
     -- the Manual Load Study definitions in NCI_LABS_MANUAL_LOAD_CTL to Step each study
     -- found in the batch of records through the process of Autoloading.
     -- The controls and process allow a "commit" on the hold table [NCI_LABS_MANUAL_LOAD_HOLD]
     -- to cause the entire batch of records to be conveyed through the entire loading process,
     -- including loading into OC.
     H_Job_Number Number;	  -- Hold the Submitted Job Id
     Hold_Number  Number;	  -- Holds Number during checking
     Hold_Found   Varchar2(1);	  -- Holds Found/Not-Found results

  Begin
     -- Prepare Message Logging for this Process, Always start a NEW Log
     Log_Util.LogSetName('LAB_MANUAL_LOAD_' || to_char(B_ID),'LABLOAD');

     -- Record that the process has started
     Log_Util.LogMessage('AL - AutoLoad Starting');

     -- Record on the Batch Status
     Update NCI_LABS_MANUAL_LOAD_BATCHES
        set BATCH_STATUS = 'X',
            STATUS_COMMENT = 'Batch Executing.'
      where BATCH_ID = B_Id;

      commit;

     -- Mark Records that have not defined study in the control table as errors.  As a
     -- Batch can have more than one study, the batch will still need processed.
     Update nci_labs_manual_load_Hold a
        set status_code = 'E',
            status_comment = 'Record has no Study ID or Inbound Study Id defined in NCI_LABS_MANUAL_LOAD_CTL.'
      where batch_id = B_ID
        and not exists (select 'X' from nci_labs_manual_load_ctl b
                                        where b.study = a.study
                                           or b.inbound_study = a.study);

     -- Capture the row count of the above query for checking and reporting below.
     Hold_number := SQL%RowCount;

     -- Check the row count. If records were affected, report them to the log.
     If Hold_Number > 0 Then
        Log_Util.LogMessage('AL - Batch '||to_char(B_ID)||' has '||to_char(Hold_Number)||
                                  ' records marked with Study Not Defined error.');
     End If;

     -- For Every Study found in the batch, that has a record in the control table
     -- process the study using its controls.
     For X in (Select A.Study, nvl(A.InBound_Study, a.Study) Inbound_Study,
                      A.AUTO_Change_hold_data,
                      A.Auto_move_to_Stage,
                      A.Auto_change_stage_data,
                      A.Auto_Move_to_loader,
                      A.Auto_Load_to_OC
                 From NCI_LABS_MANUAL_LOAD_CTL a
                 where exists (select 'X'
                                 from NCI_LABS_MANUAL_LOAD_HOLD b
                                where  1 = 1
                                  and (b.Study = NVL(A.InBound_Study,A.Study)
                                       or b.Study = A.Study)
                                  and b.status_code = 'N'
                                  and b.batch_id = B_ID) ) Loop

        -- Message for Study IN Batch
        Log_Util.LogMessage('AL - BEGINNING: Study Processing for "'||X.Study||'" in Batch '||
                            to_char(B_Id)||'.');

        -- The field Inbound_Study holds the name of the study as it is referenced outside
        -- the realm of the Lab Loader (C3D).  If the value of Inbound_Study is different
        -- than the value of Study, then there is a possibility that the outside reference is
        -- used in the Batch, and must be changed to the Study value known to Lab Loader
        If X.InBound_Study <> X.Study Then
           Log_Util.LogMessage('AL - InBound Study <> Study; Converting');

           Update NCI_LABS_MANUAL_LOAD_HOLD
              set study = X.Study
            where Batch_ID = B_ID
              and Study = X.InBound_Study;

           Log_Util.LogMessage('AL - Study Id changes for '||to_char(SQL%RowCount)||' records.');
        End If;

        -- Check Study control for manupulating Data in the HOLD table prior to moving.it to staging.
        If X.Auto_Change_Hold_Data = 'Y' Then
           -- Study requires HOLD DATA manupulation, Log a message
           Log_Util.LogMessage('AL - "'||X.Study||'" requires Auto-Change of Hold Data.');

           -- Execute the Hold Data Manipulator for this Study in this Batch
           MassageHoldData(B_ID, X.Study);
        Else
           -- Message to Log File that Study does not allow Auto-Change of data in Hold Area
           Log_Util.LogMessage('AL - "'||X.Study||'" is does not Auto-Change Hold Data.');

        End If;

        -- Count the number of records left to process.
        select count(*)
          into Hold_Number
          from NCI_LABS_MANUAL_LOAD_HOLD a
         where a.study = X.Study
           and a.Batch_ID = B_ID
           and Status_Code = 'N';

        --If the are records left, keep processing.
        If Hold_Number > 0 Then

           -- Study Control for Moving data from the Hold table to Staging Area Automatically.
           -- This is independent of the Manipulation Step above.  The steps Stage manipulator,
           -- Move to Loader and Load to OC can only occur if Move to Stage occurs.
           If X.Auto_Move_To_Stage = 'Y' Then

              -- Study requires MOVE TO STAGE, Log Message
              Log_Util.LogMessage('AL - "'||X.Study||'" is Auto Move To Stage.');

              -- Execute the Move to Stage procedure for this Study in this Batch
              MoveFromHoldToStage (B_ID, X.Study);

              -- Count the number of records left to process.
              select count(*)
                into Hold_Number
                from NCI_LABS_MANUAL_LOAD_STAGE a
               where a.study = X.Study
                 and a.Batch_ID = B_ID
                 and STATUS_FLAG = 'N';

              -- If there are records left, keep processing.
              If Hold_Number > 0 Then

                 -- Study control for manipulating data at the Staging area.
                 If X.Auto_Change_stage_data = 'Y' Then

                    -- Study requires STAGE Manipulation, Log Message
                    Log_Util.LogMessage('AL - "'||X.Study||'" is Auto Change Stage Data.');

                    -- Execute Stage Data Manipulator for this Study in this Batch
                    MassageStageData(B_Id, X.Study);

                 End If;

                 -- Count the number of records left to process.
                 select count(*)
                   into Hold_Number
                   from NCI_LABS_MANUAL_LOAD_STAGE a
                  where a.study = X.Study
                    and a.Batch_ID = B_ID
                    and STATUS_FLAG = 'N';

                 -- If there are records left, keep processing.
                 If Hold_Number > 0 Then

                    -- Study control for moving data to loader (NCI_LABS)
                    If X.Auto_Move_To_Loader = 'Y' Then

                       Log_Util.LogMessage('AL - "'||X.Study||'" is Auto Move To Loader.');

                       Begin
                           -- Check to see if Lab Loader is running in Batch Mode.  Placing "N" - New
                           -- records into NCI_LABS while it is processing could cause unexpected
                           -- results on the new records.
                           select distinct 'X'
                             into hold_Found
                             from user_jobs
                            where upper(what) like '%CDW_DATA_TRANSFER_V3.GET_PROCESS_LOAD_LABS%'
                               OR upper(what) like '%CDW_DATA_TRANSFER_V3.RELOAD_ERROR_LABS%'
                               OR upper(what) like '%CDW_DATA_TRANSFER_V3.RECHECK_UNMAPPED_LABS%';

                          -- Lab Loader is running in Batch Mode, note this in Log Message
                          Log_Util.LogMessage('AL - WARNING: Lab Loader is Executing, placing '||
                                              'data for "'||X.Study||'" into holding pattern (LOAD_FLAG="n")');

                          -- Copy the records to NCI_LABS, but use the "n" instead of "N" to denote
                          -- New records.  The Lab Loader will ingnore the "n" status, so current
                          -- processing is not impeded, the AutoLoad_Watcher will look after records
                          -- with an 'n' flag.
                          CopyFromStageToLoader(B_ID, X.Study, 'n');

                       Exception
                          When No_Data_Found Then
                             -- Lab Loader is NOT running in Batch Mode. copy study data for
      		             -- the batch to NCI_LABS with the Normal "N" flag.
   		             CopyFromStageToLoader(B_ID, X.Study, 'N');

                       End;
                       -- Study control for Loading Data to OC
                       If X.Auto_Load_To_OC = 'Y' Then

		          -- Study requires Load To OC, Log Message
		          Log_Util.LogMessage('AL - "'||X.Study||'" is Auto Load to OC.');

		          -- Execute and OutLoad to OC for Study
                          LoadToOC(X.Study);

                       End If;
                    End If;
                 Else

                    -- Message for Study having no records to process
                    Log_Util.LogMessage('AL - COMPLETED: Study Processing for "'||X.Study||'" in Batch '||
                                        to_char(B_Id)||', NO RECORDS LEFT TO PROCESS.');
                 End If;

              Else

                 -- Message for Study having no records to process
                 Log_Util.LogMessage('AL - COMPLETED: Study Processing for "'||X.Study||'" in Batch '||
                                      to_char(B_Id)||', NO RECORDS LEFT TO PROCESS.');
              End If;
           End If;

           -- Message for Study Completion
           Log_Util.LogMessage('AL - COMPLETED: Study Processing for "'||X.Study||'" in Batch '||
                            to_char(B_Id)||'.');

        Else

           -- Message for Study having no records to process
           Log_Util.LogMessage('AL - COMPLETED: Study Processing for "'||X.Study||'" in Batch '||
                            to_char(B_Id)||', NO RECORDS LEFT TO PROCESS.');
        End If;

        Commit;

     End Loop;

     -- Update the Submitted batches table with the completion date of the Batch.
     Update NCI_LABS_MANUAL_LOAD_BATCHES
        set JOB_STOP_DATE = Sysdate,
            BATCH_STATUS = 'C',
	    STATUS_COMMENT = 'Batch Completed Autoload.'
      where BATCH_ID = B_Id;

     commit;

     -- Message that processing is over.
     Log_Util.LogMessage('AL - AutoLoad Complete.');

  End;

  Procedure MassageHoldData (B_Id in Number, BStudy in Varchar) is
     -- This procedure is used to manipulate the data in the HOLD table
     -- This is executed for each study having a "Y" in the AUTO_CHANGE_HOLD_DATA
     -- column of the NCI_LABS_MANUAL_LOAD_CTL control table, AND having a
     -- valid sql script in the column HOLD_DATA_CHANGES

     Hold_Change_code Varchar2(4000);  -- Variable to hold SQL code for study data change
     Hold_Number      Number;

  Begin
     -- Alert to Message Log
     Log_Util.LogMessage('MHD - BEGINNING: Auto-Change Hold Data For "'||BStudy||
                                '"- Batch #'||To_Char(B_ID)||'.');

     -- Check the code used to change data in the HOLD table.  If it does NOT contain
     -- the Batch ID signifier "#BATCH_ID#", then send alert to log, but keep processing.
     Select instr(HOLD_DATA_CHANGES, '#BATCH_ID#')
       Into Hold_Number
       from NCI_LABS_MANUAL_LOAD_CTL
      where STUDY = BStudy;

     If Hold_Number = 0 Then
        Log_Util.LogMessage('MHD - WARNING: Hold Data Auto-Change Code for '||BStudy||
                            ' does not include a Batch Id signifier (#BATCH_ID#) and '||
                            'could potentially alter data outside of it''s own Batch!');
     End If;

     -- Get the SQL for the data change, replace the variable for Batch ID with the actual
     -- Batch_ID.  If the Code does not use BATCH_ID in its manipulation, there is a chance
     -- that the code will effect more data than expected. (See above)
     Select replace(Hold_Data_Changes, '#BATCH_ID#', to_char(B_ID))
       Into Hold_Change_Code
       from NCI_LABS_MANUAL_LOAD_CTL
      where STUDY = BStudy;

     -- Check the code to see if it is null
     If Hold_Change_Code is not null Then

        -- the code is not null, write the code to Message Log
        Log_Util.LogMessage('MHD - Using the following code for Auto-Change of Hold Data:');
        Log_Util.LogMessage(Hold_Change_Code);

        -- Execute the code held in the variable
        Execute Immediate Hold_change_Code;

        -- Log that the code was executed
        Log_Util.LogMessage('MHD - Code Executed Successfully.');
     Else

        -- Log that there was not code to execute
        Log_Util.LogMessage('MHD - No Auto-Change Code Found.');

     End If;

     -- Mark Records with new status message for completion of Auto-Change
     Update nci_labs_manual_load_Hold a
        set status_comment = 'Hold Data Auto-Change Successful.'
      where a.batch_id = B_ID
        and a.study  = BStudy;

     -- Log the number of records updated.
     Log_Util.LogMessage('MHD - '||to_char(SQL%RowCount)||' records updated with '||
                         'successful completion of Auto-Change Hold Data.');

     -- Log that the process has completed.
     Log_Util.LogMessage('MHD - COMPLETED: Auto-Change Hold Data For "'||BStudy||
                                     '" - Batch #'||To_Char(B_ID)||'.');

  Exception
     When Others then
        -- Log that there was an unknown/unexpected error.
	Log_Util.LogMessage('MHD - ERROR: MassageHoldData - Study "'||BStudy||'" / '||
	                                  'Batch "'||to_char(B_Id)||'".');
	Log_Util.LogMessage('MHD - ERROR: Error Encountered: ' || SQLCODE);
	SqlErrMsg := substr(SQLERRM,1,2000);
	Log_Util.LogMessage('MHD - ERROR: Error Message: ' || SqlErrMsg);

        -- Mark Records with error message associated with failed Auto-Change
        Update nci_labs_manual_load_Hold a
           set status_Code = 'E',
               status_comment = 'Hold Data Auto-Change Failure of "'||
                                 substr(SqlErrMsg, 1, 100)||'"...'
         where batch_id = B_ID
           and a.study  = BStudy;

        Log_Util.LogMessage('MHD - Batch '||to_char(B_ID)||' has '||to_char(SQL%RowCount)||
                                  ' records marked Hold Data Auto-Change Failure.');

  End;

  Procedure MassageStageData (B_Id in Number, BStudy in Varchar) is
     -- This procedure is used to manipulate the data in the STAGE table
     -- This is executed for each study having a "Y" in the AUTO_CHANGE_STAGE_DATA
     -- column of the NCI_LABS_MANUAL_LOAD_CTL control table, AND having a
     -- sql script in the column STAGE_DATA_CHANGES

     Hold_Change_code Varchar2(4000); -- Variable to hold SQL code for study data change
     Hold_Number      Number;         -- Holds various numbers and counters.
  Begin
     -- Log that Stage Data Manipulation is beginning
     Log_Util.LogMessage('MSD - BEGINNING: Auto-Change Stage Data For "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

     -- Check the code used to change data in the HOLD table.  If it does NOT contain
     -- the Batch ID signifier "#BATCH_ID#", then send alert to log, but keep processing.
     Select instr(STAGE_DATA_CHANGES, '#BATCH_ID#')
       Into Hold_Number
       from NCI_LABS_MANUAL_LOAD_CTL
      where STUDY = BStudy;

     If Hold_Number = 0 Then
        Log_Util.LogMessage('MSD - WARNING: Stage Data Auto-Change Code for '||BStudy||
                            ' does not include a Batch Id signifier (#BATCH_ID#) and '||
                            'could potentially alter data outside of it''s own Batch!');
     End If;

     -- Get the SQL for the data change, replace the variable for Batch ID with the actual
     -- Batch_ID.  If the Code does not use BATCH_ID in its manipulation, there is a chance
     -- that the code will effect more data than expected.
     Select replace(Stage_Data_Changes, '#BATCH_ID#', to_char(B_ID))
       Into Hold_Change_Code
       from NCI_LABS_MANUAL_LOAD_CTL
      where STUDY = BStudy;

     -- Check the code to see if it is null
      If Hold_Change_Code is not null Then

        -- the code is not null, write the code to Message Log
         Log_Util.LogMessage('MSD - Using the following code for Auto-Change of Stage Data');
         Log_Util.LogMessage(Hold_Change_Code);

        -- Execute the code held in the variable
         Execute Immediate Hold_change_Code;

        -- Log that the code was executed
         Log_Util.LogMessage('MSD - Code Executed Successfully.');
      Else

         -- Log that there was not code to execute
         Log_Util.LogMessage('MSD - No Auto-Change Code Found.');

      End If;

     -- Mark Records with new status message for completion of Auto-Change
     Update nci_labs_manual_load_Stage a
        set status_comment = 'Stage Data Auto-Change Successful.'
      where batch_id = B_ID
        and a.study  = BStudy;

     -- Log the number of records updated.
     Log_Util.LogMessage('MSD - '||to_char(SQL%RowCount)||' records updated with '||
                         'successful completion of Auto-Change Stage Data.');

     -- Log that the process has completed.
     Log_Util.LogMessage('MSD - COMPLETED: Auto-Change Stage Data For "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

  Exception
     When Others then
        -- Log that there was an unknown/unexpected error.
	Log_Util.LogMessage('MSD - ERROR: MassageStageData - Study "'||BStudy||'" / '||
	                                  'Batch "'||to_char(B_Id)||'".');
	Log_Util.LogMessage('MSD - ERROR: Error Encountered: ' || SQLCODE);
	SqlErrMsg := substr(SQLERRM,1,2000);
	Log_Util.LogMessage('MSD - ERROR: Error Message: ' || SqlErrMsg);

        -- Mark Records with error message associated with failed Auto-Change
        Update nci_labs_manual_load_Stage a
           set status_flag = 'E',
               status_comment = 'Stage Data Auto-Change Failure of "'||
                                substr(SqlErrMsg, 1, 100)||'"...'
         where batch_id = B_ID
           and a.study  = BStudy;

        Log_Util.LogMessage('MSD - Batch '||to_char(B_ID)||' has '||to_char(Hold_Number)||
                                  ' records marked Stage Data Auto-Change Failure.');

  End;

  Procedure MoveFromHoldToStage (B_Id in Number, BStudy in Varchar) is
     -- Move the data for the Study for the Batch ID from the HOLD table to the
     -- STAGING Table.

     ProcStep   Varchar2(20);
  Begin
     -- Alert the Log that the MoveFromHoldToStage procedure has begun
     Log_Util.LogMessage('MHTS - BEGINNNING: MoveFromHoldToStage for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

     -- Record the processing stage, needed if failure occurs so handler can report bad step.
     ProcStep := 'INSERT TO STAGE';

     -- Insert data into the STAGE table from the HOLD table, for the study and Batch
     -- Assign a STAGE id to the record, Create a NOTE in STAGE_NOTE.
     INSERT INTO NCI_LABS_MANUAL_LOAD_STAGE (
        STUDY,               PATIENT_ID,          OC_PATIENT_POS,
        LAB_SAMPLE_DATE_RAW, LAB_SAMPLE_TIME_RAW, LAB_TEST_NAME,
        LAB_TEST_RESULT,     LAB_TEST_UOM,        LAB_TEST_RANGE,
        LABORATORY,          RECORD_ID,           RECEIVED_DATE,
        LAB_SAMPLE_DATE,     STAGE_DATE,
        STAGE_USER,          STAGE_NOTE,
        STAGE_ID,            LAB_TEST_RANGE_LOW,  LAB_TEST_RANGE_HIGH,
        STATUS_FLAG,         PROCESS_DATE,        PROCESS_USER,
        LAB_TEST_EVENT,      QUALIFYING_VALUE,    BATCH_ID)
     SELECT
        STUDY,               PATIENT_ID,          OC_PATIENT_POS,
        LAB_SAMPLE_DATE_RAW, LAB_SAMPLE_TIME_RAW, LAB_TEST_NAME,
        LAB_TEST_RESULT,     LAB_TEST_UOM,        LAB_TEST_RANGE,
        LABORATORY,          RECORD_ID,           RECEIVED_DATE,
        NULL,                SYSDATE,
        USER,                'AUTOMOVED BATCH#('||to_char(B_Id)||')',
        NCI_MANUAL_LOAD_SEQ.nextval, LAB_TEST_RANGE_LOW,  LAB_TEST_RANGE_HIGH,
        'N',                 SYSDATE,             USER,
        LAB_TEST_EVENT,      QUALIFYING_VALUE,    BATCH_ID
       FROM NCI_LABS_MANUAL_LOAD_HOLD
      where BATCH_ID = B_ID
        and STUDY = BSTUDY;

     -- Log the number of records copied to the STAGE table.
     Log_Util.LogMessage('MHTS - '||to_char(SQL%RowCount)||' records Copied to Stage for "'||
     				  BStudy||'" - Batch #'||To_Char(B_ID)||'.');

     -- Record the processing stage, needed if failure occurs so handler can report bad step.
     ProcStep := 'DELETE FROM HOLD';

     -- Delete records from the HOLD table for the Study and Batch that were just copied.
     Delete
       from NCI_LABS_MANUAL_LOAD_HOLD
      where STUDY = BStudy
        and BATCH_ID = B_Id;

     -- Log the number of records deleted from the HOLD table.
     Log_Util.LogMessage('MHTS - '||to_char(SQL%RowCount)||' records Deleted from Hold for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

     -- Log that the procedure has ended.
     Log_Util.LogMessage('MHTS - COMPLETED: MoveFromHoldToStage for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

  Exception
    When Others then
       -- Log that there was an unknown/unexpected error.
       Log_Util.LogMessage('MHTS - ERROR: MoveFromHoldToStage @ '||ProcStep||' for "'||BStudy||
                                '"- Batch #'||To_Char(B_ID)||'.');
       Log_Util.LogMessage('MHTS - ERROR: Error Encountered: ' || SQLCODE);
       SqlErrMsg := substr(SQLERRM,1,2000);
       Log_Util.LogMessage('MHTS - ERROR: Error Message: ' || SqlErrMsg);

        -- Mark Records that have not defined study in the control table as errors.  As a
        -- Batch can have more than one study, the batch will still need processed.
        Update nci_labs_manual_load_Hold a
           set status_Code = 'E',
               status_comment = Decode(ProcStep, 'INSERT TO STAGE',
                                                 'Could Not Move To Stage',
                                                 'DELETE FROM HOLD',
                                                 'Could Not Delete From Hold',
                                                 'Other Error')||' "'||substr(SqlErrMsg, 1, 100)||'"...'
         where a.batch_id = B_ID
           and a.study  = BStudy;

        Log_Util.LogMessage('MHTS - Batch '||to_char(B_ID)||' has '||to_char(SQL%RowCount)||
                                  ' records marked with '|| ProcStep ||' Error in '||
                                  'MoveFromHoldToStage procedure.');

  End;

  Procedure CopyFromStageToLoader (B_Id in Number, BStudy in Varchar, BLoad_Flag in Varchar) is
     -- Move the data for the Study for the Batch ID from the STAGE table to the
     -- Loader Table (NCI_LABS). Caution must be used when inserting NEW data into
     -- NCI_LABS. If the Lab Loader is running at the time of the insert, there could be
     -- data inconsistency problems.

     -- Set the processing Step, used in error handler to determine locaiton of error.
     ProcStep   Varchar2(20);

  Begin
     -- Alert the Log that the MoveFromStageToLoader procedure has begun
     Log_Util.LogMessage('CSTL - BEGINNING: CopyFromStageToLoader for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

     -- Insert into NCL_LABS, study records from the Batch.
     -- Convert Smple_DateTime to the expected format.
     -- Assign to CDW_RESULT_ID (Source Identified) the Batch_ID and the Stage Id.
     -- Set the Load_Flag for NCI_LABS to "N" if there is not a batch job running,
     -- and "n" if there is.  This is done through the parameter BLoad_Flag.

     ProcStep := 'INSERT TO NCI_LABS';

     INSERT INTO NCI_LABS (
        RECORD_ID,
        PATIENT_ID,
        SAMPLE_DATETIME,
        TEST_COMPONENT_ID, LABORATORY, LABTEST_NAME,
        LAB_GRADE, RESULT, UNIT,
        NORMAL_VALUE, PANEL_NAME, PATIENT_NAME,
        COMMENTS, OC_LAB_PANEL, OC_LAB_QUESTION,
        OC_LAB_EVENT, QUALIFYING_VALUE, OC_PATIENT_POS, LOAD_DATE,
        LOAD_FLAG, RECEIVED_DATE, DATE_CREATED,
        DATE_MODIFIED, CREATED_BY, MODIFIED_BY,
        TEST_CODE, CDW_RESULT_ID, OC_STUDY,
        ERROR_REASON, OC_LAB_SUBSET, LOAD_MARK_DATE,
        LOAD_MARK_USER)
     SELECT NULL Record_ID,
            PATIENT_ID,
            to_char(LAB_SAMPLE_DATE, 'MMDDYYHH24MI') SAMPLE_DATETIME,
            NULL TEST_COMPONENT_ID,
            LABORATORY,
            LAB_TEST_NAME LABTEST_NAME,    -- added upenn
            NULL LAB_GRADE,
            LAB_TEST_RESULT RESULT,
            LAB_TEST_UOM UNIT,
            LAB_TEST_RANGE NORMAL_VALUE,
            NULL PANEL_NAME,
            NULL PATIENT_NAME,
            NULL COMMENTS,
            NULL OC_LAB_PANEL,
            LAB_TEST_NAME OC_LAB_QUESTION,  -- added upenn
            LAB_TEST_EVENT OC_LAB_EVENT,    -- added upenn
            QUALIFYING_VALUE,               -- added upenn
            OC_PATIENT_POS OC_PATIENT_POS,  -- added upenn
            NULL LOAD_DATE,
            BLoad_Flag  LOAD_FLAG,
            RECEIVED_DATE,
            NULL DATE_CREATED,
            NULL DATE_MODIFIED,
            NULL CREATED_BY,
            NULL MODIFIED_BY,
            NULL TEST_CODE,
            'ML-B'||to_Char(B_id)||'S'||to_char(Stage_ID)   CDW_RESULT_ID,
            STUDY OC_STUDY,
            NULL ERROR_REASON,
            NULL OC_LAB_SUBSET,
            NULL LOAD_MARK_DATE,
            NULL LOAD_MARK_USER
       From NCI_LABS_MANUAL_LOAD_STAGE
      where Status_Flag = 'N'
        and Study = BStudy
        and Batch_id = B_Id;

     -- Log the number of records copied to the Loader table (NCI_LABS).
     Log_Util.LogMessage('CSTL - '||to_char(SQL%RowCount)||' records Copied to Loader for "'||
                                 BStudy||'" - Batch #'||To_Char(B_ID)||'.');

     -- Set the processing Step, used in error handler to determine locaiton of error.
     ProcStep := 'UPDATE STAGE STATUS';

     -- Update the STAGE table and mark all records moved to NCI_LABS, with the Complete Status
     -- "C"
     Update NCI_LABS_MANUAL_LOAD_STAGE
        set STATUS_flag = 'C',
            STATUS_COMMENT = 'Copy to Lab Loader Successful.'
      where Status_Flag = 'N'
        and Study = BStudy
        and Batch_Id = B_Id
        and Exists (select 'x' from nci_labs
                     where cdw_result_id = 'ML-B'||to_Char(B_ID)||'S'||to_char(Stage_ID));

     -- Log the number of records updated in STAGE
     Log_Util.LogMessage('CSTL - '||to_char(SQL%RowCount)||' records marked as Completed in Stage for "'||
                                  BStudy||'" - Batch #'||To_Char(B_ID)||'.');

     -- Log that the procedure has ended.
     Log_Util.LogMessage('CSTL - COMPLETED: CopyFromStageToLoader for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');

     Commit;

  Exception
     When Others then
        -- Log that there was an unknown/unexpected error.
        Log_Util.LogMessage('CSTL - ERROR In MoveFromHoldToStage for "'||BStudy||
                                '" - Batch #'||To_Char(B_ID)||'.');
        Log_Util.LogMessage('CSTL - ERROR: Error Encountered: ' || SQLCODE);
        SqlErrMsg := Substr(SQLERRM, 1, 2000);
        Log_Util.LogMessage('CSTL - ERROR: Error Message: ' || SqlErrMsg);

        -- Mark Records that have not defined study in the control table as errors.  As a
        -- Batch can have more than one study, the batch will still need processed.
        Update nci_labs_manual_load_Stage a
           set status_Flag = 'E',
               status_comment = Decode(ProcStep, 'INSERT TO NCI_LABS',
                                                 'Could Not Move To NCI_LABS',
                                                 'UPDATE STAGE STATUS',
                                                 'Could Not Update Stage Status',
                                                 'Other Error')||' "'||substr(SqlErrMsg, 1, 100)||'"...'
         where a.batch_id = B_ID
           and a.study  = BStudy;

        Log_Util.LogMessage('MHTS - Batch '||to_char(B_ID)||' has '||to_char(SQL%RowCount)||
                                  ' records marked with '|| ProcStep ||' Error in '||
                                  'MoveFromHoldToStage procedure.');

  End;

  Procedure LoadToOC(BStudy in Varchar2, L_Type in Varchar2 Default 'NEW') is
     -- This procedure initiates a Lab Loader Job for Loading the study into OC.
     -- Lab Loader was modified to allow for a single Study to be loaded to OC, however
     -- Lab Loader still must process all studies upto the actual load step and process all
     -- records in a study that are ready for loading..
     H_Job_Number Number;       -- Hold the JOB number
     Hold_Found   Varchar2(1);  -- Holds Found/Not-Found results

  Begin
     -- Before writing to Log File, check to ensure that a Log has been created.  As
     -- this procedure can run a long time, waiting for the batch job to finish, this
     -- keeps the number of log files down.
     If Log_Util.Log$LogName is Not null Then
        -- Log that the LoadToOC procedure has begun.
        Log_Util.LogMessage('LTOC - LoadToOC - BEGIN');
        Log_Util.LogMessage('LTOC - Study="'||BStudy||'"   L_Type="'||L_Type||'".');
     End If;

     -- Check to see if the Lab Loader is currently running in Batch.  A more production method
     -- may require an execution table that holds a control to designate that the Lab Loader
     -- is executing.  This would allow for Manual starts as well as Batch Starts to be
     -- included when determining if the job is executing.
     Begin
        select distinct 'X'
          into hold_Found
          from user_jobs
         where upper(what) like '%CDW_DATA_TRANSFER_V3.GET_PROCESS_LOAD_LABS%'
            OR upper(what) like '%CDW_DATA_TRANSFER_V3.RELOAD_ERROR_LABS%'
            OR upper(what) like '%CDW_DATA_TRANSFER_V3.RECHECK_UNMAPPED_LABS%';

        If Log_Util.Log$LogName is Not null Then
           -- Log that the Lab Loader is executing and that studies should be placed in "HOLD"
           Log_Util.LogMessage('LTOC - WARNING: Lab Loader is Executing, placing Load For '||
                               BStudy||'" in holding pattern.');
        End If;

        If L_Type = 'NEW' Then
           -- put the study in the HOLD queue, because the Lab Loader is running in batch
           -- mode, as determined by the select above.
           HoldForOC(BStudy);
        End If;

     Exception
        When No_Data_Found Then

           -- Log that the submission is taking place
           If Log_Util.Log$LogName is Not null Then
              Log_Util.LogMessage('LTOC - Submitting "WAIT_PROC_MARK_LOAD" for '||BStudy);
           End If;

           -- Submit the Study for Loading using the special wait_proc_mark_load Study option
           dbms_job.submit(H_Job_Number,
                           'Begin CDW_DATA_TRANSFER_V3.GET_PROCESS_LOAD_LABS(''WAIT_PROC_MARK_LOAD('||
                           BStudy||')''); End;');

           -- Log that the job was submitted
           If Log_Util.Log$LogName is Not null Then
              Log_Util.LogMessage('LTOC - Submitted Job Number "'||to_char(H_Job_Number)||'".');
           End If;

     End;

     If Log_Util.Log$LogName is Not null Then
        Log_Util.LogMessage('LTOC - LoadToOC - DONE');
     End If;

  End;

  Procedure HoldForOC(BStudy in Varchar2) is
     -- This procedure initiate a Lab Loader Job for Loading the study into OC.
     -- Lab Loader was modified to allow for a single Study to be loaded to OC, however
     -- Lab Loader still must process all studies upto the actual load step.
     H_Job_Number Number;      -- Hold the JOB number
     Hold_Found  Varchar2(1);  -- Holds Found/Not-Found results

  Begin
     --Log that the LoadToOC procedure has begun.
     Log_Util.LogMessage('HFOC - HoldForOC - BEGIN');

     insert into NCI_LABS_AUTOLOAD_HOLD (STUDY, CREATE_DATE, CREATE_USER)
     select BStudy, sysdate, user
       from Dual
      where not exists ( select 'X' from NCI_LABS_AUTOLOAD_HOLD
                          where Study = BStudy);

     Update NCI_LABS_AUTOLOAD_HOLD
        set REQUESTS = nvl(REQUESTS,0) + 1
      where Study = BStudy;

     Commit;

  Exception
     When Others then
        -- Log that there was an unknown/unexpected error.
        Log_Util.LogMessage('HFOC - ERROR: NCI_Labs_Manual_Loader.HoldForOC for "'||BStudy||'".');
        Log_Util.LogMessage('HFOC - ERROR: Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('HFOC - ERROR: Error Message: ' || SQLERRM);
  End;

 End;

/

Show Error
