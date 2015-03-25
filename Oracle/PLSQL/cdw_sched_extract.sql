--submits delayed execution of the CDW data extract program 
declare
v_num integer;
begin
dbms_job.submit(v_num,
    'cdw_data_transfer.pull_latest_labs;',
    to_date('09-MAY-2003 06:00:00','DD-MON-YYYY HH24:MI:SS'),
    'sysdate+1');
commit;
end;
/
