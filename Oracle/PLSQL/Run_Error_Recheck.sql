Declare

   x_cnt   Number := 0;

Begin

   update nci_labs_error_labs set oc_study = '%' where cycle = 'R' and oc_study = 'E%';

   commit;

   cdw_data_transfer_v3.recheck_unmapped_labs('MARK');

   C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                   'RECHECK_UNMAPPED_LABS(''MARK'') Process Completed Successfully',
                   'RECHECK_UNMAPPED_LABS(''MARK'') Process Completed Successfully');

   cdw_data_transfer_v3.process_error_labs('MARK');

   C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                   'PROCESS_ERROR_LABS(''MARK'') Process Completed Successfully',
                   'PROCESS_ERROR_LABS(''MARK'') Process Completed Successfully');

   cdw_data_transfer_v3.get_process_load_Labs('WAIT_PROC_MARK');

   C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                   'GET_PROCESS_LOAD_LABS(''WAIT_PROC_MARK'') Process Completed Successfully',
                   'GET_PROCESS_LOAD_LABS(''WAIT_PROC_MARK'') Process Completed Successfully');

   update nci_labs_error_labs set oc_study = 'E%' where cycle = 'R' and oc_study = '%';

   commit;

   C3D_UTIL_MAILER.SEND_MAIL_FOR('CHECK_LABS','SUCCESS',
                   'RUN_ERROR_RECHECK.SQL Process Completed Successfully',
                   'RUN_ERROR_RECHECK.SQL Process Completed Successfully');

End;