CREATE OR REPLACE procedure OPS$BDL.report_errors(rptdate in date) is
file_hdl UTL_FILE.FILE_TYPE;
recsloaded number(10);
recsskipped varchar2(50);
recsprocessed number(10);
recstotal number(10);
recsadded number(5);
starttime date;
stime varchar2(30);
etime varchar2(30);
endtime date;
timetaken varchar2(200);
tlogname varchar2(50);
whrclause varchar2(2000);

r_oth_labs number(10);
r_unmapped number(10);
r_invalid_res number(10);
r_study_not_loading number(10);
r_missing_event number(10);
r_lab_not_defined number(10);
r_after_off_study number(10);
r_PreStudy_dt number(10);
r_before number(10);
r_dbl_mapped number(10);
r_subevent number(10);

cursor c_err_recs(wclause varchar2) is select distinct oc_study, test_component_id, labtest_name, error_reason from (select distinct oc_study, test_component_id, labtest_name, error_reason from nci_labs where 
load_flag = 'E' and date_created between starttime and endtime ) where (error_reason = wclause);

TYPE errrec is TABLE of c_err_recs%ROWTYPE INDEX BY PLS_INTEGER;
errcollection errrec;
cursor whrcl is select error_reason, oper, clause from error_rpt_ctl where oper is not null order by sequence;


cursor c_rec_status is select load_flag, count(*) reccount from nci_labs where date_modified between starttime and endtime group by load_flag ; 
sqlstmt varchar2(4000);
status_legend varchar2(50);
 
begin

select '''' ||error_reason||'''' into whrclause from error_rpt_ctl where oper is null; 
for i in whrcl loop
whrclause := whrclause ||' '||i.clause || ' error_reason '||i.oper||' '||''''||i.error_reason||'''';
end loop;
whrclause := whrclause ||')';
dbms_output.put_line ('whrclause = '|| whrclause);
select max(logname) into tlogname from message_logs where logname like 'LABLOAD_'||to_char(rptdate, 'YYYYMMDD')||'%' and logtext = 'GPLL - Processing Type is "FULL".';
dbms_output.put_line (tlogname);
file_hdl := UTL_FILE.FOPEN('LAB_DIR','ErrRpt.txt','W');
select logdate into starttime from message_logs where logname like tlogname and logtext = 'GPLL - Beginning "GET_PROCESS_LOAD_LABS".';
stime := to_char(starttime, 'HH24:MI:SS');
select logdate into endtime from message_logs where logname like tlogname and logtext = 'GPLL - Finished "GET_PROCESS_LOAD_LABS".';
etime := to_char(endtime, 'HH24:MI:SS');
select round((to_date(etime, 'HH24:MI:SS') - to_date(stime, 'HH24:MI:SS')) * 24,2) into timetaken from dual;
select to_number(substr(logtext,instr(logtext,'=')+2)) into recsloaded from message_logs where logname like tlogname and logtext like 'Loaded =%';
select logtext into recsskipped from message_logs where logname like tlogname and logtext like 'Skipped=%';
select to_number(substr(logtext,instr(logtext,'=')+2))- 1 into recstotal from message_logs where logname like tlogname and logtext like 'Total Records=%';
select count(*) into recsprocessed from nci_labs where date_modified between starttime and endtime;
select to_number(substr(logtext, 28,(instr(logtext, 'lab') - 29))) into recsadded  from message_logs where logname like tlogname and logtext like '% lab records for patients on more than one study, or on same study more than once.'
and logtype='LABLOAD' and logname like tlogname;

select count(*) into r_oth_labs from nci_labs where date_modified  between starttime and endtime and load_flag = 'E'and error_reason like '% does not load "Other Labs".';
select count(*) into r_unmapped from nci_labs where date_modified  between starttime and endtime and load_flag = 'E' and error_reason = 'Lab Test is unmapped';
select count(*) into r_invalid_res from nci_labs where date_modified  between starttime and endtime and load_flag = 'E' and error_reason = 'Lab Result is invalid';
select count(*) into r_study_not_loading from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason like 'Study is no longer loading labs.%';
select count(*) into r_missing_event from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason = 'Update Record missing its Event and Subevent';
select count(*) into r_lab_not_defined from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason = 'Laboratory "CDW" not defined for study.';
select count(*) into r_after_off_study from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason like '% days after Off Study Date';
select count(*) into r_PreStudy_dt from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason = 'PreStudy Lab Date is NULL.';
select count(*) into r_before from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason = 'Lab Sample Date is less than PreStudy Lab Date + Offset';
select count(*) into r_dbl_mapped from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason like '%double-mapped%';
select count(*) into r_subevent from nci_labs where date_modified between starttime and endtime and load_flag = 'E' and error_reason = 'SubEvent Has Reached 95+.  Lab Not Loaded.';

utl_file.putf(file_hdl, 'Report Date: '||to_char(sysdate,'MM/DD/YYYY') ||'\n');
utl_file.putf(file_hdl, 'LL Run Date: '||to_char(rptdate,'MM/DD/YYYY') ||'\n');
utl_file.putf(file_hdl, 'Start Time : '|| to_char(starttime, 'MM/DD/YYYY HH24:MI:SS') || '\n' );
utl_file.putf(file_hdl, 'End Time : '|| to_char(endtime, 'MM/DD/YYYY HH24:MI:SS') || '\n' );
utl_file.putf(file_hdl, 'Time Taken: '|| timetaken || ' hours \n' );
utl_file.putf(file_hdl,  'Total Records Read = '|| recstotal || '\n' );
utl_file.putf(file_hdl,  'Records Loaded from CDW file = '||recsloaded ||'\n\n' );
utl_file.putf(file_hdl,  'Records added for patients on more than 1 Study = '||recsadded ||'\n\n' );
utl_file.putf(file_hdl, 'Total records processed in the NCI_LABS table = '||recsprocessed || '\n\n');
utl_file.putf(file_hdl, r_oth_labs ||' records were not loaded due to Studies not loading Other Labs.'|| '\n\n');
utl_file.putf(file_hdl, r_unmapped ||' records were not loaded as the labs are unmapped.'||'\n\n');
utl_file.putf(file_hdl, r_invalid_res || ' records were not loaded as the results were invalid.'||'\n\n');
utl_file.putf(file_hdl, r_study_not_loading || ' records were not loaded as Study is not loading labs anymore.'||'\n\n');
utl_file.putf(file_hdl, r_missing_event || ' records were not loaded as Update records were missing event and subevent.'||'\n\n');
utl_file.putf(file_hdl, r_lab_not_defined || ' records were not loaded as Lab CDW not defined for Study.'||'\n\n');
utl_file.putf(file_hdl, r_after_off_study || ' records were not loaded as records are after Off Study Date.'||'\n\n');
utl_file.putf(file_hdl, r_PreStudy_dt || ' records were not loaded as records have a Null Pre-Study Date.'||'\n\n');
utl_file.putf(file_hdl, r_before || ' records were not loaded as records are before Pre-Study Date.'||'\n\n');
utl_file.putf(file_hdl, r_dbl_mapped ||' records were not loaded as they are double mapped.'||'\n\n');
utl_file.putf(file_hdl, r_subevent || ' records are not loaded as the Subevent has reached 95+.'||'\n\n');

-- utl_file.putf(file_hdl,  'Records '||recsskipped ||'\n' );
For i in c_rec_Status loop
case i.load_flag
when 'L' then status_legend := 'Ready to Load';
When 'X' then status_legend := 'Duplicate Records.';
when 'R' then status_legend := 'Ready for Review.';
When 'E' then status_legend := 'records which were not loaded.';
when 'W' then status_legend := 'records which are Update Records.';
when 'A' then status_legend := 'records which are Archived.';
when 'D' then status_legend := 'records with same test in more than one panel.';
when 'C' then status_legend := 'records which are loaded in C3D.';
when 'U' then status_legend := 'records which are Updated in C3D.';
else status_legend := 'records with other status.';
end case;
utl_file.putf(file_hdl, 'There are '||i.reccount|| ' '|| status_legend||'\n\n');
end loop;
dbms_output.put_line ('B4 For Loop');
--
--For i in c_err_recs(whrclause)
--loop
--dbms_output.put_line ('In For Loop');
--utl_file.putf(file_hdl,  'OC_STUDY : '||i.oc_study ||', OC_LAB_EVENT: '||i.oc_lab_event || ', ERROR: '||i.error_reason||'\n\n' );
--end loop;\\
sqlstmt := 'SELECT distinct oc_study, TEST_COMPONENT_ID, LABTEST_NAME, error_reason FROM NCI_LABS WHERE trunc(date_created) = to_date('||''''||rptdate||''''||') and load_flag = '||''''||'E'||''''||
' and ( error_reason = '|| whrclause || ' order by oc_study, error_reason';
dbms_output.put_line (sqlstmt);
EXECUTE IMMEDIATE  sqlstmt BULK COLLECT into errcollection;

dbms_output.put_line ('After For Loop ');

utl_file.putf(file_hdl, '***********ERRORS*************\n\n');
For i in 1..errcollection.count loop
utl_file.putf(file_hdl,  'OC_STUDY : '||errcollection(i).oc_study ||',Test Component ID: '||errcollection(i).test_component_id ||', Lab Test Name:'||errcollection(i).labtest_name||', ERROR: '||errcollection(i).error_reason||'\n\n' );
end loop;

--For i in c_not_loading loop
--utl_file.putf(file_hdl,  'OC_STUDY : '||i.oc_study || ', ERROR: '||i.error_reason||'\n\n' );
--end loop;
utl_file.fclose(file_hdl);

exception
when OTHERS then
dbms_output.put_line ('Error: '|| SQLERRM);

end;
/
