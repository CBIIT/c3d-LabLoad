Declare

X_Cnt      Number := 0;
            
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
   Log_Util.LogSetName('IAL_TEST_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'TESTING');

   Log_Util.LogMessage('IAL - START');

   For y_Rec in (select PT_ID from NCI_LAB_VALID_PATIENTS_VW group by PT_ID
                      having count(*) > 1) Loop -- only look at patients in multiple positions

     Log_Util.LogMessage('IAL - inside first query with patient ' ||y_Rec.PT_ID);
        
     For x_Rec in (SELECT distinct b.STUDY, b.PT, b.PT_ID, b.LABORATORY, a.CDW_RESULT_ID
                     from NCI_LABS a,
                       NCI_LAB_VALID_PATIENTS b
             WHERE b.PATIENT_ID = y_Rec.PT_ID
	       and a.PATIENT_ID = b.PT_ID
	       and a.LABORATORY = b.LABORATORY
	       and a.CDW_RESULT_ID is not null
		         MINUS
		         SELECT nvl(OC_STUDY,'~'), nvl(OC_PATIENT_POS,'~'), PATIENT_ID, LABORATORY, CDW_RESULT_ID
		           from NCI_LABS
		          where PATIENT_ID = y_Rec.PT_ID ) loop

     Log_Util.LogMessage('IAL - inside second query with result' ||x_Rec.CDW_RESULT_ID);

            
     Begin
        X_Cnt := X_Cnt + 1;

        Begin
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

         Log_Util.LogMessage('IAL - found data for ' ||x_Rec.CDW_RESULT_ID);

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

         Log_Util.LogMessage('IAL - inserted new record for result ' ||x_Rec.CDW_RESULT_ID);

        Exception
           When Others Then
              Log_Util.LogMessage('IAL - Insert New Record Failed for Result "'||X_Rec.CDW_RESULT_ID||'".');
              Log_Util.LogMessage('IAL - Insert New Record - Error Encountered: ' || SQLCODE);
              Log_Util.LogMessage('IAL - Insert New Record - Error Message: ' || SQLERRM);
        End;

     End;
     End Loop;
     Log_Util.LogMessage('IAL - finished with patient ' ||y_Rec.PT_ID);
     
  End loop;
End;