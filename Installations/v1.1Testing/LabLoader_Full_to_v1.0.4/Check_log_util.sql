spool check_log_util

-- This script will check for the Utility  LOG_UTIL.  If the utility exists,
-- the message "LOG_UTIL exists!" will appear.  If the utility does not exist, 
-- the message "LOG_UTIL does not exist and must be created!" will appear.

select 'LOG_UTIL does not exist and must be created!' "Check"
  from dual
 where not exists (
       select owner, synonym_name, table_name 
         from all_synonyms 
        where synonym_name ='LOG_UTIL'
          and owner = 'PUBLIC')
UNION
select 'LOG_UTIL exists!' "Check"
  from dual
 where exists (
       select owner, synonym_name, table_name 
         from all_synonyms 
        where synonym_name ='LOG_UTIL'
          and owner = 'PUBLIC')

/

spool off

