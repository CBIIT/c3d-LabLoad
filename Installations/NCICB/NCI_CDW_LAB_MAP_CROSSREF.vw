/* Formatted on 2005/12/09 15:34 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW nci_cdw_lab_map_crossref (test_id,
                                                               ec_id,
                                                               oth_test_id,
                                                               laboratory,
                                                               oc_lab_question
                                                              )
AS
   SELECT TO_CHAR (a.test_id) test_id, a.ec_id ec_id, b.test_id oth_test_id,
          c.laboratory, c.oc_lab_question
     FROM mis_cdr_tests a,
          mis_cdr_tests b,
          nci_lab_mapping c
    WHERE a.ec_id = b.ec_id AND b.test_id = c.test_component_id;


