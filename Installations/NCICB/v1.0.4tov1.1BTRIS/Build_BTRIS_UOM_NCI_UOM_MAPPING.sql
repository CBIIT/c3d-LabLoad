-- Script for Adding BTRIS Lab UOM values based on CDW Values into 
-- NCI_UOM_MAPPING Table

-- Step 1: Add a Lab Test UOM record to UOM Mapping table for EACH CDW mapping.
INSERT INTO NCI_UOM_MAPPING  (SOURCE, PREFERRED, LABORATORY, CREATED_DATE, CREATED_BY)
SELECT distinct SOURCE, PREFERRED, 'BTRIS', SYSDATE, USER
  FROM NCI_UOM_MAPPING A
 WHERE LABORATORY = 'CDW';
           
Commit;