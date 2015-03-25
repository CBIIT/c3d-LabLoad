create or replace Procedure NCI_LABS_JOBSUB(JobText IN Varchar2) as
-- 
-- PRC - Ekagra - 10/13/2011
-- This procedure is used by the Lab Loader Administrator UI to submit 
-- Lab Loader Batch Jobs.  By using this procedure, individual users 
-- do not have to be granted access to the DBMS_JOB package.
--
-- Usage - Send the EXACT Job statement to be executed
-- example - 'Begin NCI_LABS_RUN_W_PROCESS(''Y''); End;'
--

   JobNumber Number;
   XFound    Varchar2(1);
   v_msg     Varchar2(4000); 
   v_Step    Varchar2(20);
   crlf      Varchar2(2)   := Chr(13) ||Chr(12);

Begin

   Begin
      v_Step := 'FindJob';
      
      Select distinct 'X' 
        into XFound
        from NCI_LABS_JOBS
       where JobText like '%'||JOB_STRING||'%';
       
      v_Step := 'SubmitJob';
       
      dbms_job.submit(job=>JobNumber,
                      what=>JobText,
                      next_date=>sysdate);
      
      v_Step := 'CommitJob';

      Commit;
      
      v_Step := 'BuildEMail';

      v_msg := 'LL_JOBSUB - SUCCESS: ' || crlf ||
               'LL_JOBSUB - Job: "'||to_char(JobNumber)||'" created.' || crlf ||
   	       'LL_JOBSUB - JobText: "'||JobText||'".' || crlf;
   
      v_Step := 'SendEMail';
      
      C3D_UTIL_MAILER.Send_Mail_For('LAB_LOADER','SUCCESS','Job Submission Success (NCI_LABS_JOBSUB)',v_msg);
       
   Exception
      When Others then
          -- Log that there was an unknown/unexpected error.
          -- Log_Util.LogMessage('ALW - ERROR: AutoLoad_Watcher - Batch Processing - Batch_ID "'||X.Batch_Id||'".');
          -- Log_Util.LogMessage('ALW - ERROR: Error Encountered: ' || SQLCODE);
          -- Log_Util.LogMessage('ALW - ERROR: Error Message: ' || SQLERRM);
          -- send and e-mail
          v_msg := 'LL_JOBSUB - ERROR: NCI_LABS_JOBSUB - Step: "'||v_step||'".' || crlf ||
                   'LL_JOBSUB - ERROR: Error Encountered: ' || SQLCODE || crlf ||
   	           'LL_JOBSUB - ERROR: Error Message: ' || SQLERRM || crlf;
   
	  C3D_UTIL_MAILER.Send_Mail_For('LAB_LOADER','FAILURE','Job Submission Failure (NCI_LABS_JOBSUB)',v_msg);
    End;

End;