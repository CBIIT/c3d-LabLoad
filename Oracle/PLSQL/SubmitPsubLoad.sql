create or replace PROCEDURE submit_psub_load
 (nOS_FILE_ID in number,
  vOUT_FILE_DIR in varchar2)

IS
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*     Author: Unknown                                                               */
/*       Date: Unknown                                                               */
/*Description: Submits psub Batch Job for Lab Loading                                */
/*             (Original Description Missing)                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*  Modification History                                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad- Ekagra Software Technologies                              */
/*   Date: 07/10/03                                                                  */
/*    Mod: Added function call to update labs that received responses to questions,  */
/*         even though the batch status is Failure.  Also upped the Looping time for */
/*         batch status watching to 30 minues.                                       */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad- Ekagra Software Technologies                              */
/*   Date: 03/05/2004                                                                */
/*    Mod: Altered call to cdw_data_transfer_v3 in the Failure Clause                */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad- Ekagra Software Technologies                              */
/*   Date: 03/05/2004                                                                */
/*    Mod: Added "cdw_data_transfer_v3.Update_After_Batch_Load" call for each case   */
/*         where the Batch Job is check for completeness.                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  batch_mode      varchar2(20);
  pipename        varchar2(60);
  send_status     number;
  logfile         batch_jobs.log_file_name%TYPE;
  outfile         batch_jobs.output_file_name%TYPE;
  cmd             batch_jobs.cmd_buffer%TYPE;
  exe_status      varchar2(15);
  comp_ts         date;
  fail_text       varchar2(200);
  o_errnum        number;
  o_errmsg        varchar2(200);
  start_time      date;
  batch_q         batch_jobs.batch_queue%TYPE;
  l_batch_id   number;
  vStatus      varchar2(80);

-- vOUT_FILE_DIR must be set at the Implementation Site or USED as another input Parm;
-- this is just an example:
-- vOUT_FILE_DIR varchar2(60) := '/home/opapps/batch_load';  

cursor c_batch_q is
  select long_value
   from reference_codelist_values
   where ref_codelist_name = 'BATCH QUEUE NAME'
   and ref_codelist_value_short_val = 'RXC_BATCH_QUEUE';

 BEGIN
-- Figure out the Batch Queue

    open c_batch_q;
    fetch c_batch_q into batch_q;
    close c_batch_q;

-- Generate the Batch Job Id

   select psub_comfile_seq.nextval
     into l_batch_id
     from dual;

  dbms_output.put_line('Process Job Id = '||l_batch_id);

-- Generate the Log File Name and Output Filename

    logfile  := rxcps_pkg.log_directory ('3GL')||'l' || to_char(l_batch_id) || '.log';
    outfile  := rxcps_pkg.log_directory ('3GL')||'o' || to_char(l_batch_id) || '.out';

  dbms_output.put_line('Log File = '||logfile);
  dbms_output.put_line('Out File = '||outfile);

-- Generate the command line for all study definitions at each location
--rxcbeblt "-1/home/guest1/log/o38.out" -2-1 -3-1 "-41" "-5/" "-65" "-71" "-820" "-9300" "-10N" "-11" "-12Y"

-- example from njsun01
-- /export/home/opapps/oc/40/dm/rxcbeblt "-1$RXC_USER/temp5.lst" -2-1 -3-1 "-45" "-5/" "-6382111" "-71" "-820" "-9300" "-10N" "-11" "-12Y"

--rxcbeblt "-1/home/guest1/log/o50.out" -2-1 -3-1 "-45" "-5/" "-61607" "-71" "-820" "-9300" "-10N" "-11/home/opapps/batch_load" "-12Y" for "load/prepare/transfer"
--rxcbeblt "-1/home/guest1/log/o56.out" -2-1 -3-1 "-41" "-5/" "-61807" "-71" "-820" "-9300" "-10N" "-11" "-12Y" for "load"
--rxcbeblt "-1/home/guest1/log/o58.out" -2-1 -3-1 "-42" "-5/" "-61807" "-71" "-820" "-9300" "-10N" "-11/home/opapps/batch_load" "-12Y" for "prepare"

-- Parameter 10N defines whether to "Prepare to Completion". It's set to Y below.

 dbms_output.put_line('OS File Id = '||nOS_FILE_ID);
 cmd := 'rxcbeblt '||'"-1'||outfile ||'" "-2-1" "-3-1" "-45" "-5/" "-6'||nOS_FILE_ID||'" "-73" "-820" "-9300" "-10Y" "-11'||vOUT_FILE_DIR||'" "-12Y"';

 dbms_output.put_line('CMD = '||cmd);

-- Insert into BATCH_JOBS

      insert into batch_jobs
       (
        batch_job_id,
        entered_ts,
        execution_status,
        module_name,
        module_type,
        keep_file,
        mode_of_execution,
        db_state,
        db_state_flag,
        log_file_name,
        output_file_name,
        output_type_code,
        user_name,
        batch_queue,
        cmd_buffer,
        print_queue,
        default_rundate,
        desformat,
        schedule_server,
        job_name,
        output_width
       )
      values
       (
        l_batch_id,
        sysdate,
        'ENTERED',
        'RXCBEBLT',
        '3GL',
        'Y',
        'BATCH_IMMEDIATE',
        'N',
        'N',
        logfile,
        outfile,
        'FILE',
        USER,
        batch_q,
        cmd,
        'NOT DEFINED',
        sysdate,
        'ASCII',
        null,
        null,
        132
       );

     commit;

-- Submit the job

       rxcps_pkg.client_send
       (l_batch_id,'ENTERED_IN_BATCH_JOBS',pipename,send_status);

           o_errnum := send_status;

-- Wait for the job to complete...

             start_time := sysdate;

             loop

                select execution_status
                into exe_status
                from batch_jobs
                where batch_job_id = l_batch_id;

                if exe_status = 'SUCCESS' then
                  vStatus :='SUCCESS';
                  cdw_data_transfer_v3.Update_After_Batch_Load;
                  --UPDATE nci_labs set load_flag = 'C', load_date = sysdate WHERE LOAD_FLAG = 'N';
                  exit;
                elsif exe_status = 'FAILURE' then
                    vStatus :='FAILURE';
                  dbms_output.put_line('Batch job -'||to_char(l_batch_id)||' failed.');
                  dbms_output.put_line('  Updating those labs that received responses.'); -- prc 07/10/03 
                  cdw_data_transfer_v3.Update_After_Batch_Load; -- prc 07/10/03 -- prc 03/05/2004
                  exit;
                elsif exe_status = 'SUBMITTED' and
                  (sysdate - start_time) * 1440 > 2 then -- prc 02/01/2007: Lowered to 2 Minutes.
                  vStatus :='FAILURE';
                  cdw_data_transfer_v3.Update_After_Batch_Load;
                  exit;
                end if;

              end loop;

 EXCEPTION

    when others then
      o_errnum := SQLCODE;
      o_errmsg := SQLERRM;
      vStatus :='FAILURE';
     dbms_output.put_line('Other Error: '||o_errnum||' - '||o_errmsg);

end submit_psub_load;
/

Show errors
