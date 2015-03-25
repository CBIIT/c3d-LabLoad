
CREATE OR REPLACE FORCE VIEW NCI_CDW_LAB_MAP_CROSSREF
(TEST_ID, EC_ID, OTH_TEST_ID, LABORATORY, OC_LAB_QUESTION, 
 MAP_VERSION)
AS 
SELECT TO_CHAR (a.test_id) test_id, a.ec_id ec_id, b.test_id oth_test_id,
       c.laboratory, c.oc_lab_question, c.map_version
  FROM mis_cdr_tests a, 
       mis_cdr_tests b, 
	   nci_lab_mapping c
 WHERE a.ec_id = b.ec_id 
   AND b.test_id = c.test_component_id;


CREATE PUBLIC SYNONYM NCI_CDW_LAB_MAP_CROSSREF FOR NCI_CDW_LAB_MAP_CROSSREF;


GRANT SELECT ON  NCI_CDW_LAB_MAP_CROSSREF TO LABLOADER;

GRANT SELECT ON  NCI_CDW_LAB_MAP_CROSSREF TO LABLOADER_ADMIN;

GRANT SELECT ON  NCI_CDW_LAB_MAP_CROSSREF TO LABLOADER_REVIEW;

