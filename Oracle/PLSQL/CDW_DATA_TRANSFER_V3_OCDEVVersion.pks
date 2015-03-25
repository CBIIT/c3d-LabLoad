CREATE OR REPLACE PACKAGE cdw_data_transfer_v3 AS

  -- Global Package Variables.

  Labs_Count      Number;

  Function Find_LabMap_Version(i_StudyID in Varchar2, i_Laboratory in Varchar2) Return Varchar2;
  Function Find_Lab_Question(i_StudyID in Varchar2, i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Varchar2;
  Function Cnt_Lab_Test_Maps(i_StudyID in Varchar2, i_Test_ID in Varchar2, i_Lab_Code in Varchar2) Return Number;

  Procedure MessageLogPurge(LogName in Varchar2, LogDate in Date);

  Procedure Check_SubEvent_NUmbers;

  Procedure Get_Process_Load_Labs(Process_Type in Varchar2 default 'FULL');
  Function pull_latest_labs Return Number;
  Function pull_missed_labs Return Number;
  Function pull_Historical_labs_4(PatID in Varchar2) Return Number;

  PROCEDURE identify_duplicate_records; -- Marked Duplicate Records

  PROCEDURE Flag_UPD_Lab_Results(P_Type in Varchar2, P_Study in Varchar2 default '%');
  Procedure LLI_Processing;
  PROCEDURE prepare_cdw_labs;
  Procedure AssignPatientsToStudies;
  Procedure Identify_Additional_Labs_Old;
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

