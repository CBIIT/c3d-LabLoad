Create or replace PROCEDURE Recheck_Unmapped_Labs2(P_Method  IN VARCHAR2 DEFAULT 'HELP',
                                        P_STUDYID IN VARCHAR2 DEFAULT '%',
                                        P_TESTID  IN VARCHAR2 DEFAULT '%'     ) as
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 04/19/2012                                                            */
    /*Description: Taken from C3D Lab Loader Package                                     */
    /*             CDW_DATA_TRANSFER_V3.RECHECK_UNMAPPED_LABS                            */
    /*             Update with MORE Options                                              */
    /*             P_Method :  MARK, PROCESS, CHECK                                      */
    /*             StudyID  : (New) allows for specific Study to be checked              */
    /*             TestID   : (New) allows for specific Test ID to be checked            */
    /*             Added MORE Exception checking                                         */
    /*             Only those records getting mapped are reported                        */
    /*-----------------------------------------------------------------------------------*/
    /* Modification History:                                                             */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    v_oc_lab_question NCI_LABS.oc_lab_question%TYPE;

  BEGIN
    Log_Util.LogSetName('RECHCK_UNMAPPED2_' || TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MI'),'LABLOAD');

    Log_Util.LogMessage('RCKUMP2 - Recheck Unmapped Labs2 Starting');
    Log_Util.LogMessage('RCKUMP2 - P_METHOD  = '||P_METHOD);
    Log_Util.LogMessage('RCKUMP2 - P_STUDYID = '||nvl(P_STUDYID,'NULL'));
    Log_Util.LogMessage('RCKUMP2 - P_TESTID  = '||nvl(P_TESTID,'NULL'));

    IF UPPER(P_Method) NOT IN ('MARK','PROCESS','CHECK') THEN
        Log_Util.LogMessage('RCKUMP2 -  Parameter '||P_METHOD||' is not a valid Parameter.');
        Log_Util.LogMessage('RCKUMP2 -  ');
        Log_Util.LogMessage('RCKUMP2 -  Usage:');
        Log_Util.LogMessage('RCKUMP2 -  ');
        Log_Util.LogMessage('RCKUMP2 -  cdw_data_transerfer_pkg_new.Recheck_Unmapped_Labs(''CHECK''|''MARK''|''PROCESS'')');
        Log_Util.LogMessage('RCKUMP2 -  ');
        Log_Util.LogMessage('RCKUMP2 -  CHECK   - Reports into the log file, those labs that are NEWLY mapped and');
        Log_Util.LogMessage('RCKUMP2 -            can be used in the Marking Process.');
        Log_Util.LogMessage('RCKUMP2 -  MARK    - Marks the records as "NEW" and resets the field ERROR_REASON.');
        Log_Util.LogMessage('RCKUMP2 -            These records will then wait for the next batch of Lab Loading');
        Log_Util.LogMessage('RCKUMP2 -  PROCESS - Performs the MARK function, but will then process the records');
        Log_Util.LogMessage('RCKUMP2 -            immediately.');
        Log_Util.LogMessage('RCKUMP2 - ');
    ELSE
       IF UPPER(P_Method) IN ('MARK','PROCESS','CHECK') THEN
          -- Report The LABS that will be found as having been mapped.
           FOR Xrec IN (SELECT COUNT(*) Rec_Count, N.OC_STUDY, N.TEST_COMPONENT_ID, N.LABORATORY
                         FROM NCI_LABS n
                        WHERE load_flag = 'E'
                          AND ERROR_REASON = 'Lab Test is unmapped'
                          and OC_STUDY like nvl(P_STUDYID,'%')
                          and TEST_COMPONENT_ID like nvl(P_TESTID,'%')
                        GROUP BY N.OC_STUDY, N.Test_Component_id, n.laboratory) LOOP

              -- Find the OC Question for the Study, PASS Study to find Map Version
              v_oc_lab_question := cdw_data_transfer_v3.FIND_LAB_QUESTION(XRec.OC_STUDY, Xrec.test_component_id, XRec.laboratory);

              IF v_oc_Lab_Question IS NOT NULL THEN
                 -- Report that the Lab Test can be mapped.
                 Log_Util.LogMessage('RCKUMP2 - Study: "'||Xrec.OC_Study||'"  Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
                                     ' can be mapped to: "'|| V_OC_LAB_QUESTION ||'"  - Records Needing Update: '||
                                      TO_CHAR(Xrec.Rec_Count));

                 IF UPPER(P_Method) IN ('MARK','PROCESS') THEN
                    Begin
                       -- Mark the Records for the Study / Lab Test that were found for re-processing
                       UPDATE NCI_LABS n
                          SET Load_flag    = 'N'
                             ,Error_Reason = 'Reloaded due to: ' || Error_Reason
                        WHERE oc_study = XRec.OC_Study
                          AND load_flag = 'E'
                          AND error_Reason = 'Lab Test is unmapped'
                          AND n.test_component_id = Xrec.TEST_COMPONENT_ID
                          AND n.laboratory = XRec.Laboratory;

                       Log_Util.LogMessage('RCKUMP2 - '||TO_CHAR(SQL%RowCount)||' rows successfully marked for reprocessing.');

                       COMMIT;
                    Exception
                       WHEN OTHERS THEN
		          Log_Util.LogMessage('RCKUMP2 - WARNING: Unexpected ERROR during UPDATE.');
		          Log_Util.LogMessage('     RPED - Error Encountered: ' || SQLCODE);
                          Log_Util.LogMessage('     RPED - Error Message: ' || SQLERRM);
                    End;
                 END IF;

              -- Removed ELSE, only reporting on records needing mapped
              ELSE
                 -- Report those Lab Tests that are still not mapped.
                 Log_Util.LogMessage('RCKUMP2 - Study: "'||Xrec.OC_Study||'"  Lab: "'||Xrec.Laboratory||'"  Test_ID: "'||Xrec.TEST_COMPONENT_ID||'"'||
                                     ' STILL NOT MAPPED - Records Needing mapped: '||TO_CHAR(Xrec.Rec_Count));
              
              END IF;

          END LOOP;


       END IF;
       IF UPPER(P_Method) IN ('MARK') THEN
          Log_Util.LogMessage('RCKUMP2 - '||'Records will be processed during next Lab Load Run.');
       END IF;

       IF UPPER(P_Method) IN ('PROCESS') THEN

          Log_Util.LogMessage('RCKUMP2 - Finished "RELOAD_ERROR_LABS"');
          Log_Util.LogMessage('RCKUMP2 - Records will be processed NOW.');

          cdw_data_transfer_v3.Get_Process_Load_labs('WAITING');

       END IF;

     END IF;

     Log_Util.LogMessage('RCKUMP - Recheck Unmapped Labs Finished.');
  Exception
     WHEN OTHERS THEN
        Log_Util.LogMessage('RCKUMP2 - WARNING: Unexpected ERROR during processing...');
        Log_Util.LogMessage('     RPED - Error Encountered: ' || SQLCODE);
        Log_Util.LogMessage('     RPED - Error Message: ' || SQLERRM);
                    
  END; -- Reload_Error_Labs