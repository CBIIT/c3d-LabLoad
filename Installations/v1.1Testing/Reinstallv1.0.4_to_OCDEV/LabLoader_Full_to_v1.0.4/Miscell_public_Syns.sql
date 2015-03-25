-- Simple Install Script for CDW Data Load Public Synonyms

set echo on verify on feedback on 

Spool Miscell_Public_SYns

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

Drop public synonym DUPLICATE_LAB_MAPPINGS ;


Create public synonym DUPLICATE_LAB_MAPPINGS for &&Miscell_Object_Owner..DUPLICATE_LAB_MAPPINGS;

Spool off

undefine Miscell_Object_Owner

Set Verify off Echo off
