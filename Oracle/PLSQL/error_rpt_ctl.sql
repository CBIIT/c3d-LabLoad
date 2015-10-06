CREATE TABLE OPS$BDL.ERROR_RPT_CTL
(
  ERROR_REASON  VARCHAR2(2000 BYTE),
  OPER          VARCHAR2(10 BYTE),
  CLAUSE        VARCHAR2(10 BYTE),
  SEQUENCE      NUMBER
)
/

Insert into OPS$BDL.ERROR_RPT_CTL
   (ERROR_REASON, SEQUENCE)
 Values
   ('SubEvent Has Reached 95+.  Lab Not Loaded.', 1);
Insert into OPS$BDL.ERROR_RPT_CTL
   (ERROR_REASON, OPER, CLAUSE, SEQUENCE)
 Values
   ('%double-mapped%', 'like', 'or', 2);

COMMIT;
