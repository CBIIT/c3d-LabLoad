CREATE OR REPLACE PACKAGE cdw_load_lab_FTPdata AS

   -- Global Package Variables.

   X_Loaded         Number := 0;     -- Count of records Loaded                    
   X_Skipped        Number := 0;     -- Count of records Skipped                    

   Function Get_One_Tab_Field(IN_String in out Varchar2) Return Varchar2;

   Function Convert_Sydate_OCDate(IN_String in Varchar2) Return Varchar2;

   Procedure Parse_Check_Insert_Rec(Txt_String in Varchar2);

   Procedure Pre_Load_Setup;

   Procedure Load_Flat_File;

END cdw_load_lab_FTPdata;
/

sho  error


CREATE OR REPLACE PACKAGE BODY cdw_load_lab_FTPdata AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad- Ekagra Software Technologies                          */
  /*       Date: 04/21/2004                                                            */
  /*Description: This package is used to load CDW Lab Data that exists in a flat file  */
  /*                                                                                   */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*                                                                                   */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
Function Get_One_Tab_Field(IN_String in out Varchar2) 
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* This function is used to parse out the next tab delimited field.                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
Return Varchar2 is
   x_Temp    Varchar2(10000);
Begin
   x_temp := substr(In_String,1,Instr(In_String,Chr(9),1)-1);
   In_string := Substr(In_String,Instr(In_String,Chr(9),1)+1);
   Return X_Temp;
End;

Function Convert_Sydate_OCDate(IN_String in Varchar2) 
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Converts the text string passed to it having a format of "Mon DD YYYY HH:MI:SSAM" */
/* to a specific text date witt the format "mmddyy hh24:mi:ss" and returns it.        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
Return Varchar2 is
   x_Temp    Varchar2(10000);
Begin
   x_temp := to_char(to_date(Substr(In_String,1,20)||Substr(In_String,25,2),
                                'Mon FMDD YYYY HH:MI:SSAM'), 'mmddyy hh24:mi:ss');
   Return X_Temp;
   Exception
     When others Then
     Log_Util.LogMessage('Bad Date Convert'||SQLERRM);
     Log_Util.LogMessage('In_String = "'||In_String||'"');
End;

Procedure Parse_Check_Insert_Rec(Txt_String in Varchar2) is
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* This function is used to Parse the record passed to it, Check its patient Id and  */
/* dates to confirm loading, and insert it into the load table if needed. The Loaded */
/* and skipped counters are incremented here.                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
                       
   x_RESULT_ID            nci_upload_sybase_lab_results.RESULT_ID%Type;
   x_PATIENT_ID           nci_upload_sybase_lab_results.PATIENT_ID%Type; 
   x_RECORD_DATETIME      nci_upload_sybase_lab_results.RECORD_DATETIME%Type; 
   x_TEST_ID              nci_upload_sybase_lab_results.TEST_ID%Type;
   x_TEST_CODE            nci_upload_sybase_lab_results.TEST_CODE%Type;
   x_TEST_NAME            nci_upload_sybase_lab_results.TEST_NAME%Type;
   x_TEST_UNIT            nci_upload_sybase_lab_results.TEST_UNIT%Type;
   x_ORDER_ID             nci_upload_sybase_lab_results.ORDER_ID%Type;
   x_PARENT_TEST_ID       nci_upload_sybase_lab_results.PARENT_TEST_ID%Type; 
   x_ORDER_NUMBER         nci_upload_sybase_lab_results.ORDER_NUMBER%Type;
   x_ACCESSION            nci_upload_sybase_lab_results.ACCESSION%Type;
   x_TEXT_RESULT          nci_upload_sybase_lab_results.TEXT_RESULT%Type;
   x_NUMERIC_RESULT       nci_upload_sybase_lab_results.NUMERIC_RESULT%Type;
   x_HI_LOW_FLAG          nci_upload_sybase_lab_results.HI_LOW_FLAG%Type;
   x_UPDATED_FLAG         nci_upload_sybase_lab_results.UPDATED_FLAG%Type;
   x_LOW_RANGE            nci_upload_sybase_lab_results.LOW_RANGE%Type;
   x_HIGH_RANGE           nci_upload_sybase_lab_results.HIGH_RANGE%Type;
   x_REPORTED_DATETIME    nci_upload_sybase_lab_results.REPORTED_DATETIME%Type;
   x_RECEIVED_DATETIME    nci_upload_sybase_lab_results.RECEIVED_DATETIME%Type;
   x_COLLECTED_DATETIME   nci_upload_sybase_lab_results.COLLECTED_DATETIME%Type;
   x_MASKED               nci_upload_sybase_lab_results.MASKED%Type;
   x_RANGE                nci_upload_sybase_lab_results.RANGE%Type;
   x_SPECIMEN_ID          nci_upload_sybase_lab_results.SPECIMEN_ID%Type; 
   x_SPECIMEN_MODIFIER_ID nci_upload_sybase_lab_results.SPECIMEN_MODIFIER_ID%Type;
   x_QUALITATIVE_DICT_ID  nci_upload_sybase_lab_results.QUALITATIVE_DICT_ID%Type;
   x_INSERTED_DATETIME    nci_upload_sybase_lab_results.INSERTED_DATETIME%Type;
   x_UPDATE_DATETIME      nci_upload_sybase_lab_results.UPDATE_DATETIME%Type;

   x_hold_string          varchar2(10000);
   x_temp                 varchar2(1);
Begin
   x_hold_string := Txt_String;
   
   x_RESULT_ID             := Get_One_Tab_Field(x_hold_string);
   x_PATIENT_ID            := Get_One_Tab_Field(x_hold_string);  
   x_RECORD_DATETIME       := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string));       
   x_TEST_ID               := Get_One_Tab_Field(x_hold_string);
   x_TEST_CODE             := Get_One_Tab_Field(x_hold_string); 
   x_TEST_NAME             := Get_One_Tab_Field(x_hold_string); 
   x_TEST_UNIT             := Get_One_Tab_Field(x_hold_string); 
   x_ORDER_ID              := Get_One_Tab_Field(x_hold_string);
   x_PARENT_TEST_ID        := Get_One_Tab_Field(x_hold_string); 
   x_ORDER_NUMBER          := Get_One_Tab_Field(x_hold_string);
   x_ACCESSION             := Get_One_Tab_Field(x_hold_string);
   x_TEXT_RESULT           := Get_One_Tab_Field(x_hold_string);
   x_NUMERIC_RESULT        := Get_One_Tab_Field(x_hold_string); 
   x_HI_LOW_FLAG           := Get_One_Tab_Field(x_hold_string);
   x_UPDATED_FLAG          := Get_One_Tab_Field(x_hold_string);
   x_LOW_RANGE             := Get_One_Tab_Field(x_hold_string);
   x_HIGH_RANGE            := Get_One_Tab_Field(x_hold_string);
   x_REPORTED_DATETIME     := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
   x_RECEIVED_DATETIME     := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
   x_COLLECTED_DATETIME    := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
   x_MASKED                := Get_One_Tab_Field(x_hold_string);
   x_RANGE                 := Get_One_Tab_Field(x_hold_string);
   x_SPECIMEN_ID           := Get_One_Tab_Field(x_hold_string);
   x_SPECIMEN_MODIFIER_ID  := Get_One_Tab_Field(x_hold_string); 
   x_QUALITATIVE_DICT_ID   := Get_One_Tab_Field(x_hold_string); 
   x_INSERTED_DATETIME     := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string));
   x_UPDATE_DATETIME       := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string));
   
   Begin

      x_patient_id := lpad(x_patient_id, 7, '0'); -- prc 08/26/04  Prefix with zeros because they are dropped.      
      
      Select 'X' Into x_temp from NCI_LAB_LOAD_PATIENT_LOAD
      Where (PT_ID = x_Patient_id
             and Load_flag = 'C'
             and load_date < to_date(x_Inserted_Datetime, 'mmddyy hh24:mi:ss'))
         OR (PT_ID = x_Patient_id
             and Load_flag = 'X');

      Insert into NCI_UPLOAD_SYBASE_LAB_RESULTS 
      ( RESULT_ID              ,PATIENT_ID            ,RECORD_DATETIME
       ,TEST_ID                ,TEST_CODE             ,TEST_NAME
       ,TEST_UNIT              ,ORDER_ID              ,PARENT_TEST_ID
       ,ORDER_NUMBER           ,ACCESSION             ,TEXT_RESULT
       ,NUMERIC_RESULT         ,HI_LOW_FLAG           ,UPDATED_FLAG
       ,LOW_RANGE              ,HIGH_RANGE            ,REPORTED_DATETIME
       ,RECEIVED_DATETIME      ,COLLECTED_DATETIME    ,MASKED
       ,RANGE                  ,SPECIMEN_ID           ,SPECIMEN_MODIFIER_ID
       ,QUALITATIVE_DICT_ID    ,INSERTED_DATETIME     ,UPDATE_DATETIME
       ,UPLOAD_DATE)           
      VALUES
      ( x_RESULT_ID            ,x_PATIENT_ID          ,x_RECORD_DATETIME
       ,x_TEST_ID              ,x_TEST_CODE           ,x_TEST_NAME
       ,x_TEST_UNIT            ,x_ORDER_ID            ,x_PARENT_TEST_ID
       ,x_ORDER_NUMBER         ,x_ACCESSION           ,x_TEXT_RESULT
       ,x_NUMERIC_RESULT       ,x_HI_LOW_FLAG         ,x_UPDATED_FLAG
       ,x_LOW_RANGE            ,x_HIGH_RANGE          ,x_REPORTED_DATETIME
       ,x_RECEIVED_DATETIME    ,x_COLLECTED_DATETIME  ,x_MASKED
       ,x_RANGE                ,x_SPECIMEN_ID         ,x_SPECIMEN_MODIFIER_ID
       ,x_QUALITATIVE_DICT_ID  ,x_INSERTED_DATETIME   ,x_UPDATE_DATETIME
       ,SYSDATE);
 
      x_Loaded := x_Loaded + 1;
      
   Exception
       When No_Data_Found Then
         x_Skipped := x_Skipped + 1;
         Null;
   End;
End;

Procedure Pre_Load_Setup is
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* This procedure is used to set up Patient Load Data.  By placing this data into a  */
/* table, indexing can be used to perform faster queries.  The Patient Load Table    */
/* contains information relating to available patients, and their last load date.    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
   
   x_load_date Date;
   
Begin
   -- Clear out the Patient Load Table.
   Delete from NCI_LAB_LOAD_PATIENT_LOAD;  
   Log_Util.LogMessage('PLS - '||to_char(SQL%RowCount)||' rows successfully removed from NCI_LAB_LOAD_PATIENT_LOAD');
   
   Commit;
  
   -- Fill the Patient Load Table using the Patient Position View and the Lab Results table
   -- A load flag of 'X' denotes a NEW patient (never had lab data loaded)
   insert into NCI_LAB_LOAD_PATIENT_LOAD (PT_ID, Load_Flag)
   select distinct to_char(Patient_id), 'X' from CDW_LAB_RESULTS
   Union
   (select distinct REPLACE(PT_ID, '-', ''), 'X'
     from patient_id_ptid_vw
    where NCI_INST_CD like '%NCI%'
    minus  
   select pt_id , 'X'
     FROM patient_id_ptid_vw
    where decode(instr(translate(pt_id,
                       '/ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                       'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'),
                 'X'),0,'number','not_number') = 'not_number');
   Log_Util.LogMessage('PLS - '||to_char(SQL%RowCount)||' records successfully added to NCI_LAB_LOAD_PATIENT_LOAD');
         
   Commit;
  
   select inserted_date 
     into x_load_Date 
     from cdw_last_load;
     
   Log_Util.LogMessage('PLS - Insert Date = '||to_char(x_load_date,'MM/DD/YYYY HH24:MI:SS'));
   
   -- Update the Load date and flag for those patients that have had Labd previously loaded.
   -- Use each patients individual LOAD Date based upon raw data INSERTED DATETIME
   /*Update NCI_LAB_LOAD_PATIENT_LOAD a
     set load_flag = 'C', load_date = x_load_date
     where exists (select 'X' from CDW_LAB_RESULTS b
                    where b.patient_id = a.PT_ID);*/
     
     Update NCI_LAB_LOAD_PATIENT_LOAD a
        set load_flag = 'C',
            load_date = (select max(to_date(inserted_datetime,'MMDDRR HH24:MI:SS'))
                           from cdw_lab_results b
                          where b.patient_id = a.PT_ID)
      where exists (select 'X' from CDW_LAB_RESULTS b
                     where b.patient_id = a.PT_ID);
                     
   Log_Util.LogMessage('PLS - '||to_char(SQL%RowCount)||' records successfully updated in NCI_LAB_LOAD_PATIENT_LOAD');
                    
   Commit;

End;


Procedure Load_Flat_File is

   file_handle      UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                Number := 0;          -- Count of ALL records Read                    

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('LAB_DTAUPL_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File"'); -- prc 07/16/03

   -- Prepare Pateint Load Table
   Pre_LOAD_SETUP;
   
   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_lab_results_current.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LDU File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from NCI_UPLOAD_SYBASE_LAB_RESULTS;
      Log_Util.LogMessage('LDU - '||to_char(SQL%RowCount)||' records deleted from NCI_UPLOAD_SYBASE_LAB_RESULTS');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file (Skip line 1, it's just headers)
      X := X + 1;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        -- Parse the Record into fields. Check its Date. Insert if needed.
        Parse_Check_Insert_Rec(retrieved_buffer); 

        -- Every 10000 records read, tell the log file.
        If mod(X,10000) = 0 Then
           Log_Util.LogMessage('Read Point - Records='||to_char(X));
        End If;   
        -- Every 10000 records loaded into the NCI_UPLOAD_SYBASE_LAB_RESULTS table, commit
        If mod(X_Loaded+1,10000) = 0 Then
           Commit;
           Log_Util.LogMessage('Commit Point - Loaded Records='||to_char(X_Loaded));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File"');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
   WHEN UTL_FILE.INVALID_PATH THEN
      Log_Util.LogMessage('UTL_FILE.INVALID_PATH');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.READ_ERROR THEN
      Log_Util.LogMessage(' UTL_FILE.READ_ERROR');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.WRITE_ERROR THEN
      Log_Util.LogMessage('UTL_FILE.WRITE_ERROR');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      Log_Util.LogMessage('INVALID_FILEHANDLE');
      UTL_FILE.FCLOSE(file_handle);
   WHEN OTHERS THEN
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

END cdw_load_lab_FTPdata;
/

sho  error
