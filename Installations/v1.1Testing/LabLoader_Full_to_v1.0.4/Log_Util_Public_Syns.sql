-- Simple Install Script for Log Util Synonyms

Spool Log_Util_Public_Syns

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

Drop public synonym message_logs
/

Drop public synonym Message_Logs_Arch
/

Drop public synonym Log_Util
/

Create public synonym message_logs for &&Log_Util_Owner..message_logs
/

Create public synonym Message_Logs_Arch for &&Log_Util_Owner..message_logs_Arch
/

Create public synonym Log_Util for &&Log_Util_Owner..log_Util
/

Spool off

undefine Log_Util_owner

Set Verify off Echo off
