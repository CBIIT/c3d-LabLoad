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
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* Author: Patrick Conrad- Ekagra Software Technologies                              */
    /*   Date: 04/2011                                                                   */
    /*    Mod: Changed processing such that the primary driving query is now a FOR loop  */
    /*         and the supsequent UPDATE statement only fires if there is something to   */
    /*         update.  Also removed redundant code, i.e. there was identical code for   */
    /*         each load flag value.
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  LoopCnt  Number := 0;

  Begin
    If Log_Util.Log$LogName is null Then
       Log_Util.LogSetName('UPDATE_LOADED_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
    End If;
    Log_Util.LogMessage('UABL - Starting Update_After_Batch_Load.');

    LoopCnt := 0;
   
    For Y in (select 'L' SEL_STATUS, 'C' UPD_STATUS,
                     'Records Loaded and Verified.' UPD_TEXT, 1 ORD 
              from dual
              union
	      select 'S' SEL_STATUS, 'C' UPD_STATUS,
	             'Soft-Delete Records Reloaded and Verified .' UPD_TEXT, 2 ORD 
	      from dual
              union
	      select 'D' SEL_STATUS, 'U' UPD_STATUS,
	             'Records loaded as updates.' UPD_TEXT, 3 ORD 
	      from dual
	      union
	      select 'W' SEL_STATUS, 'U' UPD_STATUS,
	             'Records loaded as updates.' UPD_TEXT, 4 ORD 
	      from dual
	      ORDER BY ORD) Loop       
	           
       Log_Util.LogMessage('UABL - Updating for LOAD_FLAG="'||Y.SEL_STATUS||'".');

       For X in (select rowid from nci_labs
                  where Load_flag = Y.SEL_STATUS) Loop
           
         update nci_labs n
            set load_flag    = Y.UPD_STATUS,
                load_date    = sysdate,
                Error_reason = Y.UPD_TEXT
          where rowid = x.rowid
            and load_flag = Y.SEL_STATUS
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
                
          LoopCnt := LoopCnt + 1;

       End Loop;

       Log_Util.LogMessage('UABL - '||to_char(LoopCnt)||' rows successfully marked as "'||Y.UPD_TEXT||'".');

       Commit;

    End Loop;
    
    Log_Util.LogMessage('UABL - Finished Update_After_Batch_Load.');

  End; -- Update_After_Batch_Load