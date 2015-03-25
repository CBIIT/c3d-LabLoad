DECLARE
  psNum NUMBER :+ &&PatientNumberStart
  nPats NUMBER := &&NumberOfPatients;
  xCOUNT NUMBER := 0;
  Total_Count NUMBER := 0;
BEGIN
  Log_Util.LogSetName('SAMP_DATA_' || TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MI'),'LABLOAD');
  Log_Util.LogMessage('SAMP_DATA - Sample Data Builder for NCI_LABS Started.');
  Log_Util.LogMessage('SAMP_DATA - Number of Patient to add @ 53100 rows per patient = '||TO_CHAR(nPats)||'.');
  Log_Util.LogMessage('SAMP_DATA - Starting with patient position '||TO_CHAR(psNum)||'.');
  Log_Util.LogMessage('SAMP_DATA - Deleting Old Sample Data from NCI_LABS.');
  DELETE FROM NCI_LABS WHERE OC_STUDY = 'SAMP_DATA' AND oc_patient_pos >= psNum;
  Log_Util.LogMessage('SAMP_DATA - '||TO_CHAR(SQL%RowCount)||' Sample Data rows deleted (OC_STUDY = "SAMP_DATA").');
  COMMIT;
  FOR x IN psNum..psNum+nPats LOOP
    Log_Util.LogMessage('SAMP_DATA - Patient '||TO_CHAR(X)||' - Starting.');
    INSERT INTO NCI_LABS 
    SELECT NULL RECORD_ID, '9888'||LPAD(TO_CHAR(X),3,'0') PATIENT_ID, SAMPLE_DATETIME, 
           TEST_COMPONENT_ID, LABORATORY, LABTEST_NAME, 
           LAB_GRADE, RESULT, UNIT, 
           NORMAL_VALUE, PANEL_NAME, PATIENT_NAME, 
           COMMENTS, OC_LAB_PANEL, OC_LAB_QUESTION, 
           OC_LAB_EVENT, TO_CHAR(X) OC_PATIENT_POS, LOAD_DATE, 
           LOAD_FLAG, SYSDATE RECEIVED_DATE, SYSDATE DATE_CREATED, 
           SYSDATE DATE_MODIFIED, USER CREATED_BY, USER MODIFIED_BY, 
           TEST_CODE, '9888'||LPAD(TO_CHAR(X),3,'0')||LPAD(TO_CHAR(ROWNUM),5,'0') CDW_RESULT_ID, OC_STUDY, 
           ERROR_REASON, OC_LAB_SUBSET, SYSDATE LOAD_MARK_DATE, 
           USER LOAD_MARK_USER, QUALIFYING_VALUE
      FROM NCI_LABS_TEST_DATA_TMPL;	   
      xCOUNT := SQL%RowCount;
      Log_Util.LogMessage('SAMP_DATA - '||TO_CHAR(xCOUNT)||' Sample Data rows added for Patient '||TO_CHAR(X)||'.');
	  COMMIT;
      Total_Count := Total_Count + xCOUNT; 
      Log_Util.LogMessage('SAMP_DATA - '||TO_CHAR(Total_Count)||' Sample Data rows added.');
   END LOOP;
  Log_Util.LogMessage('SAMP_DATA - Sample Data Builder for NCI_LABS Finised.');
END;
