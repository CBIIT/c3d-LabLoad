-- Script for Adding BTRIS Lab Tests to the NCI_LAB_MAPPING table

-- Add a Lab Test record to Lab Mapping table for EACH dictionary version in existance for CDW.
INSERT INTO NCI_LAB_MAPPING  (TEST_COMPONENT_ID, TEST_CODE, LABORATORY, LAB_TEST, DATE_CREATED, CREATED_BY, MAP_VERSION) 
SELECT DISTINCT A.BTRIS_LAB_TEST_ID, A.LABTEST_CODE, 'BTRIS', A.LAB_TEST_NAME, SYSDATE, USER, B.MAP_VERSION 
  FROM BTRIS_LAB_TEST_NAMES A,
       (SELECT DISTINCT MAP_VERSION 
          FROM NCI_LAB_MAPPING 
         WHERE LABORATORY = 'CDW' 
           AND MAP_VERSION IS NOT NULL) B
 WHERE NOT EXISTS (SELECT 'X' FROM NCI_LAB_MAPPING c
                    WHERE c.test_component_id = a.btris_lab_test_id
                      and c.map_version = b.map_version);
                    
commit;
