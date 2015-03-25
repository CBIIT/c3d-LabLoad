CREATE TABLE MIS_PROTOCOL_LIST
(
  PCL_ID                 VARCHAR2(30 BYTE)      NOT NULL,
  PCL_TITLE              VARCHAR2(2000 BYTE),
  INITIAL_APPROVAL_DATE  VARCHAR2(30 BYTE)
)
TABLESPACE &&USERS_TABLESPACE;

CREATE INDEX MIS_PROTOCOL_LIST_INDX ON MIS_PROTOCOL_LIST
(PCL_ID)
LOGGING
TABLESPACE &&USERS_TABLESPACE;


