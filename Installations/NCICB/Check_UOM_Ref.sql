spool check_UOM_Ref

-- This script will check for the reference Table NCI_UOM_MAIN.  If the table exists,
-- the message "UOM Reference Table exists!" will appear.  If the table does not exist, 
-- the message "UOM Reference Table does not exist and must be created!" will appear.

select 'UOM Reference Table does not exist and must be created!' "Check"
  from dual
 where not exists (
       select owner, synonym_name, table_name 
         from all_synonyms 
        where synonym_name ='NCI_UOM_MAIN'
          and owner = 'PUBLIC')
UNION
select 'UOM Reference Table exists!' "Check"
  from dual
 where exists (
       select owner, synonym_name, table_name 
         from all_synonyms 
        where synonym_name ='NCI_UOM_MAIN'
          and owner = 'PUBLIC')
/

spool off

