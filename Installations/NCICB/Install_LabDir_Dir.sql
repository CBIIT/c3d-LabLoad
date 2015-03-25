spool Install_LabDir_Dir

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  
create directory LAB_DIR as '&&Lab_Batch_directory';
  
GRANT READ, WRITE  on directory LAB_DIR to PUBLIC;

spool off

