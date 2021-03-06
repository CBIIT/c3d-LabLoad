spool CDWDataLoader_Schema

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

CREATE USER &&NewUser
  IDENTIFIED BY &&password
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP1
  PROFILE OCUSER_PROFILE
  ACCOUNT UNLOCK;
  
  GRANT CONNECT TO &&NewUser;
  ALTER USER &&NewUser DEFAULT ROLE ALL;
  GRANT SELECT ANY TABLE TO &&NewUser;
  GRANT CREATE PUBLIC SYNONYM TO &&NewUser;
  GRANT DROP PUBLIC SYNONYM TO &&NewUser;
  GRANT CREATE ANY DIRECTORY TO &&NewUser;
  GRANT UNLIMITED TABLESPACE TO &&NewUser;

spool off

undefine newuser
undefine password