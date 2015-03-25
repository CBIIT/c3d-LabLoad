
CREATE INDEX OPS$BDL.NCI_LABS_TMPIDX ON OPS$BDL.NCI_LABS
(LABORATORY, LOAD_FLAG, ERROR_REASON)
LOGGING
TABLESPACE USERS
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


