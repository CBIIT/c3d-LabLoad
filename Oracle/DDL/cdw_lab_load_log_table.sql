prompt PL/SQL Developer import file
prompt Created on Monday, July 14, 2003 by ConradP
set feedback off
set define off
prompt Creating CDW_LAB_LOAD_LOG...
create table CDW_LAB_LOAD_LOG
(
  LOGNAME       VARCHAR2(30) not null,
  LOGLINENUMBER NUMBER not null,
  LOGTEXT       VARCHAR2(400),
  LOGDATE       DATE,
  LOGUSER       VARCHAR2(30)
)
tablespace USERS
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
comment on table CDW_LAB_LOAD_LOG
  is 'This table is used to record log text from the lab load process.';
alter table CDW_LAB_LOAD_LOG
  add constraint LOGNAME primary key (LOGNAME,LOGLINENUMBER)
  using index 
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

prompt Loading CDW_LAB_LOAD_LOG...
prompt Table is empty
set feedback on
set define on
prompt Done.
