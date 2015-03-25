-- Script for Adding BTRIS Lab Tests to the NCI_LAB_MAPPING table

-- Update the OC_LAB_QUESTION for each Lab Test/Version that is direct mapped.
-- If this step fails due to single-row query return multiple rows, see step 2b.
update nci_lab_mapping a
   set a.oc_lab_question = (select distinct oc_lab_question 
                              from nci_lab_mapping b 
		             where b.LAB_TEST = substr(a.lab_test,1,30) 
			       and b.test_code = a.test_code 
			       and b.map_version = a.map_version 
			       and b.laboratory = 'CDW' 
			       and b.oc_lab_question is not null)
 where a.laboratory = 'BTRIS' 
   and a.oc_lab_question is null;
   
Commit;