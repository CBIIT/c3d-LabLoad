
CREATE TABLE MESSAGE_LOGS_ARCH
(
  LOGNAME        VARCHAR2(30 BYTE)              NOT NULL,
  LOGTYPE        VARCHAR2(30 BYTE)              NOT NULL,
  LOGLINENUMBER  NUMBER                         NOT NULL,
  LOGTEXT        VARCHAR2(4000 BYTE),
  LOGDATE        DATE,
  LOGUSER        VARCHAR2(30 BYTE),
  ARCHDATE       DATE,
  ARCHUSER       VARCHAR2(30 BYTE)
)
TABLESPACE &&USERS_TABLESPACE;

Create public synonym message_logs_arch for message_logs_arch
/

grant select, insert, update, delete on message_logs_arch to public
/


