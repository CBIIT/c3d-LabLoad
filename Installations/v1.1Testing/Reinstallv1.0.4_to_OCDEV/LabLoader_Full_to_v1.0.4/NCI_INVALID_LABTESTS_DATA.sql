--
--
Insert into NCI_INVALID_LABTESTS
   (LABTEST_NAME, DATE_CREATED, CREATED_BY)
 Values
   ('.', TO_DATE('12/19/2002 13:39:58', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL');
Insert into NCI_INVALID_LABTESTS
   (LABTEST_NAME, DATE_CREATED, CREATED_BY)
 Values
   ('TEMPERATURE', TO_DATE('12/02/2004 14:39:22', 'MM/DD/YYYY HH24:MI:SS'), 'OPS$BDL');
COMMIT;
