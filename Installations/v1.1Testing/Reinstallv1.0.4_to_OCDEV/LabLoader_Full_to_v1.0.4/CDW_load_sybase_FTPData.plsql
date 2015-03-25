CREATE OR REPLACE PACKAGE cdw_load_sybase_FTPdata AS

   -- Global Package Variables.

   X_Loaded         Number := 0;     -- Count of records Loaded                    
   X_Skipped        Number := 0;     -- Count of records Skipped                    

   Function Get_One_Tab_Field(IN_String in out Varchar2) Return Varchar2;

   Function Convert_Sydate_OCDate(IN_String in Varchar2) Return Varchar2;

   Procedure Load_File_prot_Pat_CDRLIST;

   Procedure Load_File_protocol_LIST;

   Procedure Load_File_patient_LIST;
   
   Procedure Load_File_Lab_Results_Current;

   Procedure Load_File_Lab_Results_History; -- prc 07/13/2004: Added new load

   Procedure Load_File_CDR_TESTS;
   
   Procedure Load_All_Sybase_Files;
   
END cdw_load_sybase_FTPdata;
/

sho  error

CREATE OR REPLACE PACKAGE BODY cdw_load_sybase_FTPdata AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad- Ekagra Software Technologies                          */
  /*       Date: 04/21/2004                                                            */
  /*Description: This package is used to load CDW Lab Data that exists in a flat file  */
  /*                                                                                   */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*PRC 07/13/04: Added Load_FIle_Lab_Results_History procedure to handle the loading  */
  /*              of lab history data found in the Sybase FTP'ed flat file             */
  /*              "NCIC3D_cdr.vw_lab_results_history.txt"                              */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
Function Get_One_Tab_Field(IN_String in out Varchar2) 
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* This function is used to parse out the next tab delimited field.                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
Return Varchar2 is
   x_Temp    Varchar2(32767);
Begin
   If Instr(In_String,Chr(9)) = 0 Then
      x_temp := substr(In_String,1);
      In_string := Null;
   Else
      x_temp := substr(In_String,1,Instr(In_String,Chr(9),1)-1);
      In_string := Substr(In_String,Instr(In_String,Chr(9),1)+1);
   End If;
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

Procedure Load_File_prot_Pat_CDRLIST is

   file_handle      UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer VARCHAR2(32000);      -- Line BUFFER retrieved from flat file
   x_hold_string    VARCHAR2(32000);      -- Line BUFFER retrieved from flat file
   X                Number := 0;          -- Count of ALL records Read                    
   xPROTOCOLID      mis_prot_pat_cdrlist.PROTOCOLID%type;
   xMPI             mis_prot_pat_cdrlist.MPI%type;
   xMRN             mis_prot_pat_cdrlist.MRN%type;
   xLASTNAME        mis_prot_pat_cdrlist.LASTNAME%type;
   xMIDDLEINITIAL   mis_prot_pat_cdrlist.MIDDLEINITIAL%type; 
   xFIRSTNAME       mis_prot_pat_cdrlist.FIRSTNAME%type; 
   xSUFFIX          mis_prot_pat_cdrlist.SUFFIX%type; 
   xPATIENTMISNAME  mis_prot_pat_cdrlist.PATIENTMISNAME%type;


BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Prot_Pat_CDRList');

   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_protocol_patient_cdrlist.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from MIS_PROT_PAT_CDRLIST;

      Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_PROT_PAT_CDRLIST');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer);
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        -- Parse the Record into fields. Check its Date. Insert if needed.
        x_hold_string := retrieved_buffer; 

        xPROTOCOLID       := Get_One_Tab_Field(x_hold_string); 
        xMPI              := Get_One_Tab_Field(x_hold_string); 
        xMRN              := Get_One_Tab_Field(x_hold_string); 
        xLASTNAME         := Get_One_Tab_Field(x_hold_string); 
        xMIDDLEINITIAL    := Get_One_Tab_Field(x_hold_string); 
        xFIRSTNAME        := Get_One_Tab_Field(x_hold_string); 
        xSUFFIX           := Get_One_Tab_Field(x_hold_string); 
        xPATIENTMISNAME   := Get_One_Tab_Field(x_hold_string); 
        
        xMPI := lpad(xMPI, 7, '0'); -- prc 08/26/04  Prefix with zeros because they are dropped.      

        insert into MIS_PROT_PAT_CDRLIST 
           (PROTOCOLID,  MPI,  MRN,  LASTNAME,  MIDDLEINITIAL,  FIRSTNAME,  SUFFIX,  PATIENTMISNAME)
        Values
           (xPROTOCOLID, xMPI, xMRN, xLASTNAME, xMIDDLEINITIAL, xFIRSTNAME, xSUFFIX, xPATIENTMISNAME);

        X_loaded := X_loaded + 1;

        -- Every 25 records read, tell the log file.
        If mod(X,25) = 0 Then
           Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
        End If;   
        -- Every 50 records loaded into the target table, commit
        If mod(X_Loaded,50) = 0 Then
           Commit;
           Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" for MIS_PROT_PAT_CDRLIST');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" for MIS_PROT_PAT_CDRLIST');
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

Procedure Load_File_protocol_LIST is

   file_handle      UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   x_hold_string    VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                Number := 0;          -- Count of ALL records Read                    
   xpcl_id          mis_protocol_list.pcl_id%type;
   xpcl_Title       mis_protocol_list.pcl_title%type;
   xinit_app_date   mis_protocol_list.initial_approval_date%type;
   xHold            varchar2(32767);

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Vw_Protocol_Info');

   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_protocol_info.txt','r',32767);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from MIS_PROTOCOL_LIST;

      Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_PROTOCOL_LIST.');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer);
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        -- Parse the Record into fields. Check its Date. Insert if needed.
        x_hold_string := retrieved_buffer; 
        --Log_Util.LogMessage('LFF - buffer Size = '||to_char(Length(retrieved_buffer)));
        --Log_Util.LogMessage('LFF - x_hold_string = '||substr(x_hold_string,1,500));
        
        --x_loaded := 1;
        --The Line read must be checked, because some fields contain returns, that make the
        --Get_LINE function believe it has read the entire record.
        xHold            := Get_One_Tab_Field(x_hold_string);  
        If xhold is not null and length(XHold)= 9 Then
           xpcl_id := xHold;
           xHold            := Get_One_Tab_Field(x_hold_string); 
           xpcl_title      := substr(Get_One_Tab_Field(x_hold_string),1,2000); 
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xHold            := Get_One_Tab_Field(x_hold_string); -- skip this field
           xinit_app_date   := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 


           insert into MIS_PROTOCOL_LIST 
              (PCL_ID,   PCL_TITLE,   INITIAL_APPROVAL_DATE)
           Values
              (xPCL_ID,  xPCL_TITLE,  xINIT_APP_DATE);
           X_loaded := X_loaded + 1;

           -- Every 25 records read, tell the log file.
           If mod(X,25) = 0 Then
              Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
           End If;   
           -- Every 50 records loaded into the target table, commit
           If mod(X_Loaded, 50) = 0 Then
              Commit;
              Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
           End If;   
        End If;
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" for Sybase_Vw_Protocol_Info');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" for Sybase_Vw_Protocol_Info');
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
      Log_Util.LogMessage('Error occurred on Records '||to_char(X)||'-'||to_char(X_Loaded));
      Log_Util.LogMessage('Hold_String = '||substr(x_hold_string,1,500));
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

Procedure Load_File_patient_LIST is

   file_handle      UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   x_hold_string    VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                Number := 0;          -- Count of ALL records Read                    
   xmpi             mis_patient_list.mpi%type;
   xmrn             mis_patient_list.mrn%type;
   xcreated_date    mis_patient_list.created_date%type;
   xHold            varchar2(32767);

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Vw_Patient_Biography');

   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_patient_biography.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from MIS_PATIENT_LIST;

      Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_PATIENT_LIST.');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer);
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        -- Parse the Record into fields. Check its Date. Insert if needed.
        x_hold_string := retrieved_buffer; 
        
        xmpi            := Get_One_Tab_Field(x_hold_string);  
        xmrn            := Get_One_Tab_Field(x_hold_string); 
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xHold           := Get_One_Tab_Field(x_hold_string); -- skip this field
        xcreated_date   := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 

        xmpi := lpad(xmpi, 7, '0'); -- prc 08/26/04  Prefix with zeros because they are dropped.      

        insert into MIS_PATIENT_LIST 
              (MPI,   MRN,   CREATED_DATE)
        Values
              (xMPI,  xMRN,  xCREATED_DATE);

        X_loaded := X_loaded + 1;

        -- Every 50 records read, tell the log file.
        If mod(X,50) = 0 Then
           Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
        End If;   
        -- Every 100 records loaded into the target table, commit
        If mod(X_Loaded,100) = 0 Then
           Commit;
           Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Patient_Biography');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Patient_Biography');
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
      Log_Util.LogMessage('Error occurred on Records '||to_char(X)||'-'||to_char(X_Loaded));
      Log_Util.LogMessage('Hold_String = '||substr(x_hold_string,1,500));
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

Procedure Load_File_Lab_Results_Current is

   file_handle            UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer       VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   x_hold_string          VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                      Number := 0;          -- Count of ALL records Read                    
   x_RESULT_ID            MIS_LAB_RESULTS_CURRENT.RESULT_ID%Type;
   x_MPI                  MIS_LAB_RESULTS_CURRENT.MPI%Type; 
   x_DATE_TIME            MIS_LAB_RESULTS_CURRENT.DATE_TIME%Type; 
   x_TEST_ID              MIS_LAB_RESULTS_CURRENT.TEST_ID%Type;
   x_TEST_CODE            MIS_LAB_RESULTS_CURRENT.TEST_CODE%Type;
   x_TEST_NAME            MIS_LAB_RESULTS_CURRENT.TEST_NAME%Type;
   x_TEST_UNIT            MIS_LAB_RESULTS_CURRENT.TEST_UNIT%Type;
   x_ORDER_ID             MIS_LAB_RESULTS_CURRENT.ORDER_ID%Type;
   x_PARENT_TEST_ID       MIS_LAB_RESULTS_CURRENT.PARENT_TEST_ID%Type; 
   x_ORDER_NUMBER         MIS_LAB_RESULTS_CURRENT.ORDER_NUMBER%Type;
   x_ACCESSION            MIS_LAB_RESULTS_CURRENT.ACCESSION%Type;
   x_TEXT_RESULT          MIS_LAB_RESULTS_CURRENT.TEXT_RESULT%Type;
   x_NUMERIC_RESULT       MIS_LAB_RESULTS_CURRENT.NUMERIC_RESULT%Type;
   x_HI_LOW_FLAG          MIS_LAB_RESULTS_CURRENT.HI_LOW_FLAG%Type;
   x_UPDATED_FLAG         MIS_LAB_RESULTS_CURRENT.UPDATED_FLAG%Type;
   x_LOW_RANGE            MIS_LAB_RESULTS_CURRENT.LOW_RANGE%Type;
   x_HIGH_RANGE           MIS_LAB_RESULTS_CURRENT.HIGH_RANGE%Type;
   x_REPORTED_DATETIME    MIS_LAB_RESULTS_CURRENT.REPORTED_DATETIME%Type;
   x_RECEIVED_DATETIME    MIS_LAB_RESULTS_CURRENT.RECEIVED_DATETIME%Type;
   x_COLLECTED_DATETIME   MIS_LAB_RESULTS_CURRENT.COLLECTED_DATETIME%Type;
   x_MASKED               MIS_LAB_RESULTS_CURRENT.MASKED%Type;
   x_RANGE                MIS_LAB_RESULTS_CURRENT.RANGE%Type;
   x_SPECIMEN_ID          MIS_LAB_RESULTS_CURRENT.SPECIMEN_ID%Type; 
   x_SPECIMEN_MODIFIER_ID MIS_LAB_RESULTS_CURRENT.SPECIMEN_MODIFIER_ID%Type;
   x_QUALITATIVE_DICT_ID  MIS_LAB_RESULTS_CURRENT.QUALITATIVE_DICT_ID%Type;
   x_INSERTED_DATETIME    MIS_LAB_RESULTS_CURRENT.INSERTED_DATETIME%Type;
   x_UPDATE_DATETIME      MIS_LAB_RESULTS_CURRENT.UPDATE_DATETIME%Type;

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Vw_Lab_Results_Current'); -- prc 07/16/03
   
   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_lab_results_current.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from MIS_LAB_RESULTS_CURRENT;
      Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_LAB_RESULTS_CURRENT');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file (Skip line 1, it's just headers)
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        x_hold_string := retrieved_buffer;

        x_RESULT_ID             := Get_One_Tab_Field(x_hold_string);
        x_MPI                   := Get_One_Tab_Field(x_hold_string);  
        x_DATE_TIME             := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string));       
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

        x_MPI := lpad(x_MPI, 7, '0'); -- prc 08/26/04  Prefix with zeros because they are dropped.      

        Insert into MIS_LAB_RESULTS_CURRENT 
        ( RESULT_ID              ,MPI                   ,DATE_TIME
         ,TEST_ID                ,TEST_CODE             ,TEST_NAME
         ,TEST_UNIT              ,ORDER_ID              ,PARENT_TEST_ID
         ,ORDER_NUMBER           ,ACCESSION             ,TEXT_RESULT
         ,NUMERIC_RESULT         ,HI_LOW_FLAG           ,UPDATED_FLAG
         ,LOW_RANGE              ,HIGH_RANGE            ,REPORTED_DATETIME
         ,RECEIVED_DATETIME      ,COLLECTED_DATETIME    ,MASKED
         ,RANGE                  ,SPECIMEN_ID           ,SPECIMEN_MODIFIER_ID
         ,QUALITATIVE_DICT_ID    ,INSERTED_DATETIME     ,UPDATE_DATETIME)           
        VALUES
        ( x_RESULT_ID            ,x_MPI                 ,x_DATE_TIME
         ,x_TEST_ID              ,x_TEST_CODE           ,x_TEST_NAME
         ,x_TEST_UNIT            ,x_ORDER_ID            ,x_PARENT_TEST_ID
         ,x_ORDER_NUMBER         ,x_ACCESSION           ,x_TEXT_RESULT
         ,x_NUMERIC_RESULT       ,x_HI_LOW_FLAG         ,x_UPDATED_FLAG
         ,x_LOW_RANGE            ,x_HIGH_RANGE          ,x_REPORTED_DATETIME
         ,x_RECEIVED_DATETIME    ,x_COLLECTED_DATETIME  ,x_MASKED
         ,x_RANGE                ,x_SPECIMEN_ID         ,x_SPECIMEN_MODIFIER_ID
         ,x_QUALITATIVE_DICT_ID  ,x_INSERTED_DATETIME   ,x_UPDATE_DATETIME);
   
        x_Loaded := x_Loaded + 1;

        -- Every 10000 records loaded into the Target table, commit
        If mod(X_Loaded,10000) = 0 Then
           Commit;
           Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
           -- Every 50000 records read, tell the log file.
        End If;   
        If mod(X,50000) = 0 Then
           Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Lab_Results_Current');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Lab_Results_Current');
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
      Log_Util.LogMessage('Error occurred on Records '||to_char(X)||'-'||to_char(X_Loaded));
      Log_Util.LogMessage('Hold_String = '||substr(x_hold_string,1,500));
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

Procedure Load_File_Lab_Results_History is
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*Modification History                                             */
/* 02/14/2006:PRC: Removed statements related to the deleting of   */
/*                 data from MIS_LAB_RESULTS_HISTORY as this data  */
/*                 may be incremental instead of all_inclusive     */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

   file_handle            UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer       VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   x_hold_string          VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                      Number := 0;          -- Count of ALL records Read                    
   x_RESULT_ID            MIS_LAB_RESULTS_CURRENT.RESULT_ID%Type;
   x_MPI                  MIS_LAB_RESULTS_CURRENT.MPI%Type; 
   x_DATE_TIME            MIS_LAB_RESULTS_CURRENT.DATE_TIME%Type; 
   x_TEST_ID              MIS_LAB_RESULTS_CURRENT.TEST_ID%Type;
   x_TEST_CODE            MIS_LAB_RESULTS_CURRENT.TEST_CODE%Type;
   x_TEST_NAME            MIS_LAB_RESULTS_CURRENT.TEST_NAME%Type;
   x_TEST_UNIT            MIS_LAB_RESULTS_CURRENT.TEST_UNIT%Type;
   x_ORDER_ID             MIS_LAB_RESULTS_CURRENT.ORDER_ID%Type;
   x_PARENT_TEST_ID       MIS_LAB_RESULTS_CURRENT.PARENT_TEST_ID%Type; 
   x_ORDER_NUMBER         MIS_LAB_RESULTS_CURRENT.ORDER_NUMBER%Type;
   x_ACCESSION            MIS_LAB_RESULTS_CURRENT.ACCESSION%Type;
   x_TEXT_RESULT          MIS_LAB_RESULTS_CURRENT.TEXT_RESULT%Type;
   x_NUMERIC_RESULT       MIS_LAB_RESULTS_CURRENT.NUMERIC_RESULT%Type;
   x_HI_LOW_FLAG          MIS_LAB_RESULTS_CURRENT.HI_LOW_FLAG%Type;
   x_UPDATED_FLAG         MIS_LAB_RESULTS_CURRENT.UPDATED_FLAG%Type;
   x_LOW_RANGE            MIS_LAB_RESULTS_CURRENT.LOW_RANGE%Type;
   x_HIGH_RANGE           MIS_LAB_RESULTS_CURRENT.HIGH_RANGE%Type;
   x_REPORTED_DATETIME    MIS_LAB_RESULTS_CURRENT.REPORTED_DATETIME%Type;
   x_RECEIVED_DATETIME    MIS_LAB_RESULTS_CURRENT.RECEIVED_DATETIME%Type;
   x_COLLECTED_DATETIME   MIS_LAB_RESULTS_CURRENT.COLLECTED_DATETIME%Type;
   x_MASKED               MIS_LAB_RESULTS_CURRENT.MASKED%Type;
   x_RANGE                MIS_LAB_RESULTS_CURRENT.RANGE%Type;
   x_SPECIMEN_ID          MIS_LAB_RESULTS_CURRENT.SPECIMEN_ID%Type; 
   x_SPECIMEN_MODIFIER_ID MIS_LAB_RESULTS_CURRENT.SPECIMEN_MODIFIER_ID%Type;
   x_QUALITATIVE_DICT_ID  MIS_LAB_RESULTS_CURRENT.QUALITATIVE_DICT_ID%Type;
   x_INSERTED_DATETIME    MIS_LAB_RESULTS_CURRENT.INSERTED_DATETIME%Type;
   x_UPDATE_DATETIME      MIS_LAB_RESULTS_CURRENT.UPDATE_DATETIME%Type;

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Vw_Lab_Results_History');
   
   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_lab_results_history.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      -- PRC 02/14/2006 : Removed statements related to DELETE of history data
      -- Delete from MIS_LAB_RESULTS_HISTORY;
      -- Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_LAB_RESULTS_HISTORY');
      -- Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file (Skip line 1, it's just headers)
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        x_hold_string := retrieved_buffer;

        x_RESULT_ID             := Get_One_Tab_Field(x_hold_string);
        x_MPI                   := Get_One_Tab_Field(x_hold_string);  
        x_DATE_TIME             := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string));       
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
        
        x_MPI := lpad(x_MPI, 7, '0'); -- prc 08/26/04  Prefix with zeros because they are dropped.              

        Insert into MIS_LAB_RESULTS_HISTORY 
        ( RESULT_ID              ,MPI                   ,DATE_TIME
         ,TEST_ID                ,TEST_CODE             ,TEST_NAME
         ,TEST_UNIT              ,ORDER_ID              ,PARENT_TEST_ID
         ,ORDER_NUMBER           ,ACCESSION             ,TEXT_RESULT
         ,NUMERIC_RESULT         ,HI_LOW_FLAG           ,UPDATED_FLAG
         ,LOW_RANGE              ,HIGH_RANGE            ,REPORTED_DATETIME
         ,RECEIVED_DATETIME      ,COLLECTED_DATETIME    ,MASKED
         ,RANGE                  ,SPECIMEN_ID           ,SPECIMEN_MODIFIER_ID
         ,QUALITATIVE_DICT_ID    ,INSERTED_DATETIME     ,UPDATE_DATETIME)           
        VALUES
        ( x_RESULT_ID            ,x_MPI                 ,x_DATE_TIME
         ,x_TEST_ID              ,x_TEST_CODE           ,x_TEST_NAME
         ,x_TEST_UNIT            ,x_ORDER_ID            ,x_PARENT_TEST_ID
         ,x_ORDER_NUMBER         ,x_ACCESSION           ,x_TEXT_RESULT
         ,x_NUMERIC_RESULT       ,x_HI_LOW_FLAG         ,x_UPDATED_FLAG
         ,x_LOW_RANGE            ,x_HIGH_RANGE          ,x_REPORTED_DATETIME
         ,x_RECEIVED_DATETIME    ,x_COLLECTED_DATETIME  ,x_MASKED
         ,x_RANGE                ,x_SPECIMEN_ID         ,x_SPECIMEN_MODIFIER_ID
         ,x_QUALITATIVE_DICT_ID  ,x_INSERTED_DATETIME   ,x_UPDATE_DATETIME);
   
        x_Loaded := x_Loaded + 1;

        -- Every 25000 records read, tell the log file.
        If mod(X,25000) = 0 Then
           Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
        End If;   
        -- Every 10000 records loaded into the Target table, commit
        If mod(X_Loaded,10000) = 0 Then
           Commit;
           Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Lab_Results_History');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('LFF - Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('LFF - Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('LFF - Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Lab_Results_History');
   WHEN UTL_FILE.INVALID_PATH THEN
      Log_Util.LogMessage('UTL_FILE.INVALID_PATH');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.READ_ERROR THEN
      Log_Util.LogMessage('UTL_FILE.READ_ERROR');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.WRITE_ERROR THEN
      Log_Util.LogMessage('UTL_FILE.WRITE_ERROR');
      UTL_FILE.FCLOSE(file_handle);
   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      Log_Util.LogMessage('INVALID_FILEHANDLE');
      UTL_FILE.FCLOSE(file_handle);
   WHEN OTHERS THEN
      Log_Util.LogMessage('Error occurred on Records '||to_char(X)||'-'||to_char(X_Loaded));
      Log_Util.LogMessage('Hold_String = '||substr(x_hold_string,1,500));
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

Procedure Load_File_CDR_TESTS is

   file_handle      UTL_FILE.FILE_TYPE;   -- file handle of OS flat file
   retrieved_buffer VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   x_hold_string    VARCHAR2(32767);      -- Line BUFFER retrieved from flat file
   X                Number := 0;          -- Count of ALL records Read                    
   xTEST_ID          MIS_CDR_TESTS.TEST_ID%type;
   xEC_ID            MIS_CDR_TESTS.EC_ID%type;
   xTEST_CODE        MIS_CDR_TESTS.TEST_CODE%type;
   xTEST_UNIT        MIS_CDR_TESTS.TEST_UNIT%type;
   xTEST_NAME        MIS_CDR_TESTS.TEST_NAME%type;
   xTEST_TYPE        MIS_CDR_TESTS.TEST_TYPE%type;
   xABBREVIATED_NAME MIS_CDR_TESTS.ABBREVIATED_NAME%type;
   xTEST_TIME        MIS_CDR_TESTS.TEST_TIME%type;
   xADDED_DATE       MIS_CDR_TESTS.ADDED_DATE%type;
   xEFFECTIVE_DATE   MIS_CDR_TESTS.EFFECTIVE_DATE%type;
   xMODIFIED_DATE    MIS_CDR_TESTS.MODIFIED_DATE%type;
   xFIRST_RESULT_ID  MIS_CDR_TESTS.FIRST_RESULT_ID%type;
   xLAST_RESULT_ID   MIS_CDR_TESTS.LAST_RESULT_ID%type;
   xHold            varchar2(32767);

BEGIN  
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load Flat File" of Sybase_Vw_Cdr_Test');

   -- Open the file to read from
   file_handle := UTL_FILE.FOPEN('LAB_FTP','NCIC3D_cdr.vw_cdr_test.txt','r',5000);
   if UTL_FILE.IS_OPEN (file_Handle) then
      Log_Util.LogMessage('LFF File Open - '||to_char(sysdate,'HH24:MI:SS'));
      
      -- Clear all previously loaded flat file records
      Delete from MIS_CDR_TESTS;

      Log_Util.LogMessage('LFF - '||to_char(SQL%RowCount)||' records deleted from MIS_CDR_TESTS.');
      Commit;

      UTL_FILE.GET_LINE (file_handle, retrieved_buffer);
      X := X + 1;
      x_Skipped := 1;
      X_Loaded := 0;
      Loop
        UTL_FILE.GET_LINE (file_handle, retrieved_buffer); -- read file
        X := X + 1;

        -- Parse the Record into fields. Check its Date. Insert if needed.
        x_hold_string := retrieved_buffer; 
        
        xTEST_ID               := Get_One_Tab_Field(x_hold_string);  
        xEC_ID                 := Get_One_Tab_Field(x_hold_string); 
        xTEST_CODE             := Get_One_Tab_Field(x_hold_string); 
        xTEST_UNIT             := Get_One_Tab_Field(x_hold_string); 
        xTEST_NAME             := Get_One_Tab_Field(x_hold_string); 
        xTEST_TYPE             := Get_One_Tab_Field(x_hold_string); 
        xABBREVIATED_NAME      := Get_One_Tab_Field(x_hold_string); 
        xTEST_TIME             := Get_One_Tab_Field(x_hold_string); 
        xADDED_DATE            := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
        xEFFECTIVE_DATE        := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
        xMODIFIED_DATE         := Convert_Sydate_OCDate(Get_One_Tab_Field(x_hold_string)); 
        xFIRST_RESULT_ID       := Get_One_Tab_Field(x_hold_string); 
        xLAST_RESULT_ID        := Get_One_Tab_Field(x_hold_string); 


        insert into MIS_CDR_TESTS 
              (TEST_ID,        EC_ID,           TEST_CODE,         TEST_UNIT, 
               TEST_NAME,      TEST_TYPE,       ABBREVIATED_NAME,  TEST_TIME, 
               ADDED_DATE,     EFFECTIVE_DATE,  MODIFIED_DATE,     FIRST_RESULT_ID, 
               LAST_RESULT_ID)
        Values
              (xTEST_ID,       xEC_ID,          xTEST_CODE,        xTEST_UNIT, 
               xTEST_NAME,     xTEST_TYPE,      xABBREVIATED_NAME, xTEST_TIME, 
               xADDED_DATE,    xEFFECTIVE_DATE, xMODIFIED_DATE,    xFIRST_RESULT_ID, 
               xLAST_RESULT_ID);

        X_loaded := X_loaded + 1;

        -- Every 500 records read, tell the log file.
        If mod(X,500) = 0 Then
           Log_Util.LogMessage('LFF - Read Point - Records='||to_char(X));
        End If;   
        -- Every 250 records loaded into the target table, commit
        If mod(X_Loaded,250) = 0 Then
           Commit;
           Log_Util.LogMessage('LFF - Commit Point - Loaded Records='||to_char(X_Loaded));
        End If;   
      End Loop;

   Else
      Log_Util.LogMessage('LFF - NOT OPEN');
   End If;

   UTL_FILE.FCLOSE(file_handle);
   Commit;
   Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Cdr_Test');
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Log_Util.LogMessage('no_data_found - '||to_char(Sysdate,'HH24:MI:SS'));
      Commit;
      UTL_FILE.FCLOSE(file_handle);
      Log_Util.LogMessage('Loaded = '||to_char(x_Loaded));
      Log_Util.LogMessage('Skipped= '||to_char(x_Skipped));
      Log_Util.LogMessage('Total Records= '||to_char(X));
      Log_Util.LogMessage('LFF - Ending "Load Flat File" of Sybase_Vw_Cdr_Test');
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
      Log_Util.LogMessage('Error occurred on Records '||to_char(X)||'-'||to_char(X_Loaded));
      Log_Util.LogMessage('Hold_String = '||substr(x_hold_string,1,500));
      Log_Util.LogMessage('other stuff '||SQLERRM);
      UTL_FILE.FCLOSE(file_handle);
END;

Procedure Load_All_Sybase_Files is
Begin
   -- Prepare for Message Logging
   If Log_Util.Log$LogName is null Then
      Log_Util.LogSetName('SYBASE_DATALD_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'DATALOAD');
   End If;
   
   Log_Util.LogMessage('LFF - Starting "Load_All_Sybase_Files".');


   Load_File_prot_Pat_CDRLIST;

   Load_File_protocol_LIST;

   Load_File_patient_LIST;
   
   Load_File_Lab_Results_Current;
   
   Load_File_Lab_Results_History;

   Load_File_CDR_TESTS;

   Log_Util.LogMessage('LFF - Finished "Load_All_Sybase_Files".');
   
   Log_Util.LogPurgePrior('SYBASE_DATALD%','DATALOAD',SYSDATE-14,FALSE);

End;


END cdw_load_sybase_FTPdata;
/

sho  error
