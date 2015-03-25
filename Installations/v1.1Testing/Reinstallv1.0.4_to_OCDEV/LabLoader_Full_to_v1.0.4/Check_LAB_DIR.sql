spool check_LAB_DIR

-- This script will check for the reference to the directory LAB_DIR. This directory is used as
-- the location batch load temporary processing files. If the directory exists,
-- the message "LAB_DIR Directory exists!" will appear.  If the directory does not exist, 
-- the message "LAB_DIR Directory does not exist and must be created!" will appear.

select 'LAB_DIR Directory does not exist and must be created!' "Check"
  from dual
 where not exists (
       select OWNER, DIRECTORY_NAME, DIRECTORY_PATH 
         from all_directories
        where directory_name ='LAB_DIR')
UNION
select 'LAB_DIR Directory exists!' "Check"
  from dual
 where exists (
       select OWNER, DIRECTORY_NAME, DIRECTORY_PATH 
         from all_directories
        where directory_name ='LAB_DIR')
/

spool off
