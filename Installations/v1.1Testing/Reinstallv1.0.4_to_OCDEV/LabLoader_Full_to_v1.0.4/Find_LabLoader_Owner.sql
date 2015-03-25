-- Find the owner of the Log_Util utility

set lines 80 heading off echo off timing off feedback off

spool find_LabLoader_owner 

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

select Owner "Lab Loader Owner" 
  from dba_objects 
 where object_name = 'CDW_DATA_TRANSFER_V3'
   and object_type <> 'SYNONYM'
/

spool off

