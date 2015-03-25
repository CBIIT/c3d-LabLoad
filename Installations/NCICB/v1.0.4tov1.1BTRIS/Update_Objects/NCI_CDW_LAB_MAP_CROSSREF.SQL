CREATE OR REPLACE FORCE VIEW NCI_CDW_LAB_MAP_CROSSREF
(TEST_ID, EC_ID, OTH_TEST_ID, LABORATORY, OC_LAB_QUESTION, 
 MAP_VERSION)
AS 
SELECT TO_CHAR (a.test_id) test_id, 
       a.ec_id ec_id, TO_CHAR(b.test_id) oth_test_id,
       c.laboratory, c.oc_lab_question, c.map_version 
  FROM mis_cdr_tests a, 
       mis_cdr_tests b, 
       NCI_LAB_MAPPING c 
 WHERE a.ec_id = b.ec_id 
   AND TO_CHAR(b.test_id) = c.test_component_id
/

