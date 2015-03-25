-- Script for Adding BTRIS Lab Tests to the NCI_LAB_MAPPING table

-- Update the OC_LAB_QUESTION for each Lab Test/Version that is can be cross-reference.
update nci_lab_mapping a
   set oc_lab_question = (select distinct c.oc_lab_question 
                              from NCI_CDW_LAB_MAP_CROSSREF c,
                                   MIS_CDR_TESTS b
                             where b.TEST_NAME = a.lab_test 
                               and b.test_code = a.test_code
                               and c.TEST_ID = b.TEST_ID
			       and c.map_version = a.map_version
			       and c.oc_lab_question is not null)
 where oc_lab_question is null
   and laboratory = 'BTRIS';
   
Commit;   