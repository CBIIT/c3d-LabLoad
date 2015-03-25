spool check_FTP_DIR

-- This script will check for the reference the directory LAB_FTP. This directory is used as
-- the location for FLAT RAW ASCII Lab Test data files.  If the directory exists,
-- the message "LAB_FTP Directory exists!" will appear.  If the directory does not exist, 
-- the message "LAB_FTP Directory does not exist and must be created!" will appear.

select 'LAB_FTP Directory does not exist and must be created!' "Check"
  from dual
 where not exists (
       select OWNER, DIRECTORY_NAME, DIRECTORY_PATH 
         from all_directories
        where directory_name ='LAB_FTP')
UNION
select 'LAB_FTP Directory exists!' "Check"
  from dual
 where exists (
       select OWNER, DIRECTORY_NAME, DIRECTORY_PATH 
         from all_directories
        where directory_name ='LAB_FTP')
/

spool off
