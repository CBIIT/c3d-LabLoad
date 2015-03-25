create or replace Procedure NCI_LABS_RUN_W_PROCESS(SingleRun IN Varchar2 default 'N', EAlerts in Varchar2 Default 'Y') as

   x_cnt   Number := 0;
   tx_cnt  Number := 0;
   rx_Cnt  Number := 0;
   I_cnt   Number := 0;
   W_Cnt   Number := 0;

   eMailCode Varchar2(20) := 'RUN_W_PROC';


Begin

   update nci_labs_error_labs set oc_study = 'A%' where cycle = 'R' and oc_study = '%';

   update nci_labs set load_flag = 'w' where load_flag = 'W';
   commit;

   select count(*) into x_cnt
     from nci_labs where load_flag = 'w';

   tx_cnt := x_cnt;

   Loop

      Exit when x_cnt = 0;
      I_cnt := I_cnt + 1;

      If EAlerts = 'Y' Then
         C3D_UTIL_MAILER.SEND_MAIL_FOR(eMailCOde,'SUCCESS',
                'PROCESSING NCI_LABS_RUN_W_PROCESS MORE LABS',
                'The Run_W_Labs process found '||to_char(x_cnt) ||' record(s) to process.  Continuing...');
      End If;

      /* PRC changed "not exists" clause to use index NCI_LABS_LLI */
      update nci_labs a 
         set load_flag = 'W' 
       where load_flag = 'w' and 
              cdw_result_id in (
                      select min(cdw_result_id) from nci_labs
                       where load_flag = 'w'
                       group by oc_study, oc_patient_pos, oc_lab_event, sample_datetime
                                )
         and not exists (select 'X' from nci_labs b
                          where b.load_flag = 'L'
                            and b.oc_study        = a.oc_study
                            and b.oc_patient_pos  = a.oc_patient_pos
                            and b.oc_lab_event    = a.oc_lab_event
                            and b.sample_datetime = a.sample_datetime);  
            
      If EAlerts = 'Y' Then
         C3D_UTIL_MAILER.SEND_MAIL_FOR(eMailCOde,'SUCCESS',
                'NCI_LABS_RUN_W_PROCESS PROCESSING MORE LABS',
                'The Run_W_Labs is working on ' || to_char(SQL%RowCount) ||' record(s) out of the '||
                 to_char(x_cnt) ||' total record(s) needing processed.  Continuing...');

      End If;

      commit;

      select count(*) into x_cnt
        from nci_labs where load_flag = 'W';

      rx_cnt := rx_cnt + x_cnt;

      cdw_data_transfer_v3.get_process_load_Labs('WAITING');

      select count(*) into W_cnt
        from nci_labs where load_flag = 'W';

      If (W_Cnt <> 0 and EAlerts = 'Y') Then
         C3D_UTIL_MAILER.SEND_MAIL_FOR(eMailCOde,'WARNING',
                'NCI_LABS_RUN_W_PROCESS Task WARNING',
                'NCI_LABS_RUN_W_PROCESS completed an interaction, but found that '|| to_char(W_CNT) ||
                ' record(s) out of '|| to_char(x_cnt) || 'records(s) were not updated to complete.');
      End If;

      If SingleRun = 'Y' Then
         x_cnt := 0;
      Else 
         select count(*) into x_cnt
           from nci_labs where load_flag = 'w';
      End If;

    End Loop;

   update nci_labs_error_labs set oc_study = '%' where cycle = 'R' and oc_study = 'A%';

   commit;

   C3D_UTIL_MAILER.SEND_MAIL_FOR(eMailCOde,'SUCCESS',
                'NCI_LABS_RUN_W_PROCESS COMPLETED TASK',
                'NCI_LABS_RUN_W_PROCESS Task has completed.  Started with ' || to_char(tx_cnt) ||
                ' record(s) to be processed.  '|| to_char(rx_cnt) ||' total record(s) processed.  '||
                to_char(I_cnt) ||' iterations performed.');

   commit;

End;