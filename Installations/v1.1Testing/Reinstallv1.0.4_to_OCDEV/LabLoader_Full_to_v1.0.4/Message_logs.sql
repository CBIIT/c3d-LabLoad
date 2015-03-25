create table message_logs
(logName varchar2(30) not null,
 logType varchar2(30) not null,
 loglinenumber number not null,
 logtext varchar2(400),
 logdate date,
 loguser varchar2(30))
TABLESPACE &&USERS_TABLESPACE;

create index message_logs_idx on message_logs (logName, LogType, LogLineNumber)
/

Create public synonym message_logs for message_logs
/

grant select, insert, update, delete on message_logs to public
/
