spool LabLoader_Schema

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

CREATE USER &&NewUser
  IDENTIFIED BY &&password
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP1
  PROFILE OCUSER_PROFILE
  ACCOUNT UNLOCK;
  
  GRANT CONNECT TO &&NewUser;
  GRANT RXC_ANY TO &&NewUser;
  GRANT RXC_RDC TO &&NewUser;
  GRANT RESOURCE TO &&NewUser;
  GRANT DTK_ADMIN TO &&NewUser;
  GRANT RXC_SUPER TO &&NewUser;
  GRANT OCL_ACCESS TO &&NewUser;
  GRANT RDC_ACCESS TO &&NewUser;
  GRANT RXCLIN_MOD TO &&NewUser;
  GRANT RXCLIN_READ TO &&NewUser;
  GRANT RXC_BDL_TEST TO &&NewUser;
  ALTER USER &&NewUser DEFAULT ROLE ALL;
  GRANT SELECT ANY TABLE TO &&NewUser;
  GRANT CREATE PUBLIC SYNONYM TO &&NewUser;
  GRANT DROP PUBLIC SYNONYM TO &&NewUser;
  GRANT CREATE ANY DIRECTORY TO &&NewUser;
  GRANT UNLIMITED TABLESPACE TO &&NewUser;

  GRANT SELECT ON  RXC.DCM_QUES_REPEAT_DEFAULTS TO &&NewUser;
  GRANT INSERT ON  RXC.OS_FILES TO &&NewUser;
  GRANT SELECT ON  RXC.OS_FILE_SEQ TO &&NewUser;
  GRANT SELECT ON  RXC.PSUB_COMFILE_SEQ TO &&NewUser;
  GRANT SELECT ON  RXC.DCIS TO &&NewUser;
  GRANT EXECUTE ON RXC.RXCPS_PKG to &&NewUser;
  
  --explicit grant needed when owning pocedures referencing RXC objects;
  Grant select, insert, update, delete on rxc.batch_jobs to &&newuser;
  
  Create Role LABLOADER;

  Create Role LABLOADER_REVIEW;

  Create Role LABLOADER_ADMIN;

spool off

undefine newuser
undefine password