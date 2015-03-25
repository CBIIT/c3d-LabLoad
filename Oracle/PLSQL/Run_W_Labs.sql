Declare

   x_cnt   Number := 0;
   tx_cnt  Number := 0;
   rx_Cnt  Number := 0;
   I_cnt   Number := 0;

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

      C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                'PROCESSING MORE LABS',
                'The Run_W_Labs process found '||to_char(x_cnt) ||' record(s) to process.  Continuing...');

      /* Removed the "L" processing section because it kept getting executed
         due to users of LLI
      select count(*) into x_cnt
        from nci_labs where load_flag = 'L';

      If x_cnt > 0 Then
         cdw_data_transfer_v3.get_process_load_Labs('WAITING');
      End if; 
      */

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
                            and b.oc_study = a.oc_study
                            and b.oc_patient_pos = a.oc_patient_pos
                            and b.sample_datetime = a.sample_datetime);  
            
      C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                'PROCESSING MORE LABS',
                'The Run_W_Labs is working on ' || to_char(SQL%RowCount) ||' record(s) out of the '||
                 to_char(x_cnt) ||' total record(s) needing processed.  Continuing...');

      commit;

      select count(*) into x_cnt
        from nci_labs where load_flag = 'w';

      rx_cnt := rx_cnt + x_cnt;

      cdw_data_transfer_v3.get_process_load_Labs('WAITING');

      select count(*) into x_cnt
        from nci_labs where load_flag = 'w';

    End Loop;

   update nci_labs_error_labs set oc_study = '%' where cycle = 'R' and oc_study = 'A%';

   commit;

   C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                'COMPLETED TASK',
                'The Run_W_Labs Task has completed.  Started with ' || to_char(tx_cnt) ||
                ' record(s) to be processed.  '|| to_char(rx_cnt) ||' total record(s) processed.  '||
                to_char(I_cnt) ||' iterations performed.');

   commit;

End;