  Procedure Identify_Additional_Labs is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* This section is used to added additional records to NCI_LABS for processing */
  /* by identifying new study/patients relationships for existin patients.  Also */
  /* resets those errors held in the automatic error reset control table.        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* Author: Patrick Conrad- Ekagra Software Technologies                        */
  /*   Date: 04/2011                                                             */
  /*    Mod: Changed the processing such that only those patients who are on more*/
  /*         than one study that could possibly need additional records is the   */
  /*         primary driving query.  It then uses each patient to determine if   */
  /*         there are new records to duplicate, and if so, does it.             */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

      X_Cnt      Number := 0;
      Y_Cnt      Number := 0;
      T_Cnt      Number := 0;

      xSAMPLE_DATETIME     nci_labs.sample_datetime%type;
      xTEST_COMPONENT_ID   nci_labs.test_component_id%type;
      xLABTEST_NAME        nci_labs.labtest_name%type;
      xLAB_GRADE           nci_labs.lab_grade%type;
      xRESULT              nci_labs.result%type;
      xUNIT                nci_labs.unit%type;
      xNORMAL_VALUE        nci_labs.normal_value%type;
      xPANEL_NAME          nci_labs.panel_name%type;
      xPATIENT_NAME        nci_labs.patient_name%type;
      xCOMMENTS            nci_labs.comments%type;
      xRECEIVED_DATE       nci_labs.received_date%type;
      xTEST_CODE           nci_labs.test_code%type;

  Begin
     process_error_labs;  -- added 10/19/2005

     AssignPatientsToStudies;

     -- Generate additional lab records for patient on more than one study.or on same study more than once.
     Begin
        Log_Util.LogMessage('IAL - Starting Additional Record Inserts');

        T_Cnt := 0;
        Y_Cnt := 0;

        For Y_Rec in (select pt_id from NCI_LAB_VALID_PATIENTS T
                       group by  pt_id
                      having count(*) > 1)  Loop
              
           Log_Util.LogMessage('IAL - Doing PT '||to_char(Y_REC.PT_ID)||'.');
           X_Cnt := 0;
           Y_Cnt := Y_Cnt + 1;
       
           For X_Rec in (select distinct b.STUDY, b.PT, b.PT_ID, b.LABORATORY, a.CDW_RESULT_ID
                       from nci_labs a, nci_lab_valid_patients b
                      where a.PATIENT_ID = b.PT_ID
                        and a.LABORATORY = b.LABORATORY
                        and a.cdw_result_id is not null
                       and b.pt_id = Y_Rec.PT_id
                        and not exists (select 'X' from nci_labs c
                                         Where c.cdw_result_id = a.cdw_result_id
                                           and c.oc_study = b.study
                                           and c.laboratory = b.laboratory
                                           and c.oc_patient_pos = b.pt)) Loop

          Begin
             X_Cnt := X_Cnt + 1;
             T_Cnt := T_Cnt + 1;  

             select SAMPLE_DATETIME,     TEST_COMPONENT_ID,     LABTEST_NAME,
                    LAB_GRADE,           RESULT,                UNIT,
                    NORMAL_VALUE,        PANEL_NAME,            PATIENT_NAME,
                    COMMENTS,            RECEIVED_DATE,         TEST_CODE
               into xSAMPLE_DATETIME,    xTEST_COMPONENT_ID,    xLABTEST_NAME,
                    xLAB_GRADE,          xRESULT,               xUNIT,
                    xNORMAL_VALUE,       xPANEL_NAME,           xPATIENT_NAME,
                    xCOMMENTS,           xRECEIVED_DATE,        xTEST_CODE
               from nci_labs
              where cdw_result_id = x_rec.cdw_result_id
                and rownum = 1;
            --order by record_id;
	 
       Exception
             When No_Data_Found Then
                Log_Util.LogMessage('IAL - No record found for Result "'||X_Rec.CDW_RESULT_ID||'".');
       End;
       
       Begin
          Insert into NCI_LABS
                 (RECORD_ID,         PATIENT_ID,          SAMPLE_DATETIME,       TEST_COMPONENT_ID,
                  LABORATORY,        LABTEST_NAME,        LAB_GRADE,             RESULT,
                  UNIT,              NORMAL_VALUE,        PANEL_NAME,            PATIENT_NAME,
                  COMMENTS,          OC_LAB_PANEL,        OC_LAB_QUESTION,       OC_LAB_EVENT,
                  OC_PATIENT_POS,    LOAD_DATE,           LOAD_FLAG,             RECEIVED_DATE,
                  DATE_CREATED,      DATE_MODIFIED,       CREATED_BY,            MODIFIED_BY,
                  TEST_CODE,         CDW_RESULT_ID,       OC_STUDY,              ERROR_REASON,
                  OC_LAB_SUBSET)
          Values (NULL,              X_Rec.PT_ID,         xSAMPLE_DATETIME,      xTEST_COMPONENT_ID,
                  X_Rec.LABORATORY,  xLABTEST_NAME,       xLAB_GRADE,            xRESULT,
                  xUNIT,             xNORMAL_VALUE,       xPANEL_NAME,           xPATIENT_NAME,
                  xCOMMENTS,         NULL,                NULL,                  NULL,
                  X_Rec.PT,          NULL,                'N',                   xRECEIVED_DATE,
                  SYSDATE,           NULL,                USER,                  NULL,
                  xTEST_CODE,        X_Rec.CDW_RESULT_ID, X_Rec.STUDY,           NULL,
                  NULL);
       Exception
          When Others Then
             Log_Util.LogMessage('IAL - No record found for Result "'||X_Rec.CDW_RESULT_ID||'".');
             Log_Util.LogMessage('IAL - Insert New Record - Error Encountered: ' || SQLCODE);
             Log_Util.LogMessage('IAL - Insert New REcord - Error Message: ' || SQLERRM);
       End;
       
   End loop;
   Log_Util.LogMessage('IAL - End of PT '||to_char(Y_REC.PT_ID)||' @ '||to_char(X_Cnt)||' records.');

End Loop;
   Log_Util.LogMessage('IAL - Finished Additional Record Inserts.');
   Log_Util.LogMessage('IAL - Processed '||to_char(Y_Cnt)||' Patients');

   Log_Util.LogMessage('IAL - Generated additional '||to_char(T_Cnt)||
                             ' lab records for patients on more than one study, or on same study more than once.');
End;
End Identify_Additional_Labs;