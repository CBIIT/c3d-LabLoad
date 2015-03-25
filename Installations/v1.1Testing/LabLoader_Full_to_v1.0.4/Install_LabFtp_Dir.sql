spool Install_LabFtp_Dir

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  
create directory LAB_FTP as '&&lab_directory';
  
GRANT READ on directory LAB_FTP to PUBLIC;

spool off

undefine newuser
