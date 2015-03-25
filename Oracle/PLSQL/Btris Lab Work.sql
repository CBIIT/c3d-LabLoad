SELECT COUNT(*), oc_study, load_flag FROM NCI_LABS
WHERE laboratory = 'BTRIS'
GROUP BY oc_study, load_flag;

SELECT COUNT(*), oc_study, load_flag, error_reason FROM NCI_LABS
WHERE load_flag = 'E' AND laboratory = 'BTRIS'
GROUP BY oc_study, load_flag, error_reason;

UPDATE NCI_LABS 
SET load_flag = 'N', error_reason = 'Reload due to :'|| error_reason 
WHERE load_flag = 'E' AND error_reason LIKE 'Study % does not load "Other Labs".'
AND laboratory = 'BTRIS';

COMMIT;

INSERT INTO BTRIS_LAB_TEST_NAMES 
   (BTRIS_LAB_TEST_ID, LAB_TEST_NAME, LABTEST_CODE, LAB_UNIT, 
    LAB_RANGE, FIRST_REPORT_DATE, LAST_REPORT_DATE)
SELECT * 
FROM (SELECT BTRIS_LAB_TEST_ID, 
             LAB_TEST_NAME, 
             LABTEST_CODE, 
	         LAB_UNIT, 
      	     LAB_RANGE, 
	         MIN(LAB_REPORT_DATE) FIRST_REPORT_DATE, 
      	     MAX(LAB_REPORT_DATE) LAST_REPORT_DATE
        FROM BTRIS_LAB_RESULTS
       GROUP BY BTRIS_LAB_TEST_ID, LAB_TEST_NAME, LABTEST_CODE, LAB_UNIT, LAB_RANGE) A
 WHERE NOT EXISTS (SELECT NULL 
                      FROM BTRIS_LAB_TEST_NAMES B
		 			 WHERE B.BTRIS_LAB_TEST_ID = A.BTRIS_LAB_TEST_ID  
                       AND B.LAB_TEST_NAME = A.LAB_TEST_NAME 
                       AND B.LABTEST_CODE = A.LABTEST_CODE 
                       AND NVL(B.LAB_UNIT,'~') = NVL(A.LAB_UNIT,'~') 
                       AND NVL(B.LAB_RANGE,'~') = NVL(A.LAB_RANGE,'~'));

INSERT INTO NCI_LAB_MAPPING  (TEST_COMPONENT_ID, TEST_CODE, LABORATORY, LAB_TEST, DATE_CREATED, CREATED_BY, MAP_VERSION) 
SELECT DISTINCT A.BTRIS_LAB_TEST_ID, A.LABTEST_CODE, 'BTRIS', A.LAB_TEST_NAME, SYSDATE, USER, B.MAP_VERSION 
  FROM BTRIS_LAB_TEST_NAMES A,
       (SELECT DISTINCT MAP_VERSION 
          FROM NCI_LAB_MAPPING 
         WHERE LABORATORY = 'CDW' 
           AND MAP_VERSION IS NOT NULL) B
 WHERE NOT EXISTS (SELECT 'X' FROM NCI_LAB_MAPPING c
                    WHERE c.test_component_id = a.btris_lab_test_id)

--UPDATE NCI_LAB_MAPPING a
--   SET oc_lab_question = (SELECT DISTINCT c.oc_lab_question 
SELECT * FROM NCI_LAB_MAPPING  a
WHERE EXISTS (SELECT DISTINCT c.oc_lab_question 
                              FROM NCI_CDW_LAB_MAP_CROSSREF c,
                                   MIS_CDR_TESTS b
                             WHERE b.TEST_NAME = a.lab_test 
                               AND b.test_code = a.test_code
                               AND c.TEST_ID = b.TEST_ID
			       AND c.map_version = a.map_version
			       AND c.oc_lab_question IS NOT NULL)
 AND  oc_lab_question IS NULL
   AND laboratory = 'BTRIS';
					
SELECT * 
  FROM NCI_LAB_MAPPING  a,
       NCI_LAB_MAPPING  b,
	   NCI_CDW_LAB_MAP_CROSSREF c
 WHERE a.oc_lab_question IS NULL
   AND a.laboratory = 'BTRIS'
   AND c.oth_test_id = b.test_component_id
   AND b.oc_lab_question IS NOT NULL
   AND b.laboratory = 'CDW'
   AND a.test_code = b.test_code
   AND A.LAB_TEST = b.LAB_TEST
   AND a.map_version = b.map_version

SELECT * 
  FROM NCI_CDW_LAB_MAP_CROSSREF c,
       MIS_CDR_TESTS d
   WHERE c.ec_id = 'BMD2'
     AND c.test_id = d.test_id 

SELECT a.test_component_id, a.test_code, a.laboratory, a.lab_test, a.map_version,
       b.test_component_id, c.test_id, c.oth_test_id, b.test_code, c.ec_id, b.laboratory, b.lab_test, b.map_version 
  FROM NCI_LAB_MAPPING a,
       NCI_LAB_MAPPING b,
	   NCI_CDW_LAB_MAP_CROSSREF c,
	   MIS_CDR_TESTS d
 WHERE b.oc_lab_question IS NOT NULL
   AND b.laboratory = 'CDW'
   AND TO_CHAR(c.oth_test_id) = TO_CHAR(b.test_component_id)
   AND c.map_version = b.map_version
   AND d.test_id = c.test_id
   AND a.oc_lab_question IS NULL
   AND a.laboratory  = 'BTRIS'
   AND a.test_code   = d.test_code
   --AND A.LAB_TEST    = d.TEST_NAME
   AND a.map_version = b.map_version
 ORDER BY a.lab_test, a.test_component_id, a.map_version, c.ec_id
   
   

					
SELECT * FROM BTRIS_LAB_TEST_NAMES B WHERE create_date IS NOT NULL

UPDATE NCI_LAB_MAPPING a
   SET oc_lab_question = (SELECT DISTINCT c.oc_lab_question 
                              FROM NCI_CDW_LAB_MAP_CROSSREF c,
                                   MIS_CDR_TESTS b
                             WHERE b.TEST_NAME = a.lab_test 
                               AND b.test_code = a.test_code
                               AND c.TEST_ID = b.TEST_ID
			       AND c.map_version = a.map_version
			       AND c.oc_lab_question IS NOT NULL)
 WHERE oc_lab_question IS NULL
   AND laboratory = 'BTRIS'
   
SELECT COUNT(*) FROM NCI_LAB_MAPPING WHERE laboratory = 'BTRIS' AND oc_lab_question IS NOT NULL;   

SELECT COUNT(*) Rec_Count, N.OC_STUDY, N.TEST_COMPONENT_ID, N.LABORATORY
                         FROM NCI_LABS n
                        WHERE load_flag = 'E'
                          AND ERROR_REASON = 'Lab Test is unmapped'
                        GROUP BY N.OC_STUDY, N.Test_Component_id, n.laboratory

 	INDEX NAME	UNIQUE?	COLUMN NAME	ORDER	Position	INDEX Owner

PLAIN	NCI_LABS_ERR2	N	OC_STUDY	ASC	1	OPS$BDL
PLAIN	NCI_LABS_ERR2	N	LOAD_FLAG	ASC	2	OPS$BDL
PLAIN	NCI_LABS_ERR2	N	ERROR_REASON	ASC	3	OPS$BDL
PLAIN	NCI_LABS_ERR2	N	TEST_COMPONENT_ID	ASC	4	OPS$BDL
PLAIN	NCI_LABS_ERR2	N	LABORATORY	ASC	5	OPS$BDL
						
						
DELETE FROM PLAN_TABLE;

EXPLAIN PLAN FOR				

COUNTER,OC_STUDY,LOAD_FLAG,LABORATORY,TEST_COMPONENT_ID,ERROR_REASON

SELECT /*+ hint index(n, NCI_LABS_ERR2) */  COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY
  FROM NCI_LABS n, 
       NCI_CDW_LAB_MAP_CROSSREF a, 
	   NCI_LAB_LOAD_STUDY_CTLS_VW b 
 WHERE n.load_flag = 'E' 
   AND n.ERROR_REASON = 'Lab Test is unmapped'
   AND n.OC_STUDY = b.OC_STUDY 
   AND n.LABORATORY = b.LABORATORY
   AND n.TEST_COMPONENT_ID = a.TEST_ID
   AND a.LABORATORY = b.LABORATORY 
   AND a.MAP_VERSION = b.MAP_VERSION 
   AND a.OC_LAB_QUESTION IS NOT NULL 
GROUP BY n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY			
UNION			
SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY
  FROM NCI_LABS n, 
       NCI_LAB_MAPPING a, 
	   NCI_LAB_LOAD_STUDY_CTLS_VW b 
 WHERE n.load_flag = 'E' 
   AND n.ERROR_REASON = 'Lab Test is unmapped'
   AND n.OC_STUDY = b.OC_STUDY 
   AND n.LABORATORY = b.LABORATORY
   AND n.TEST_COMPONENT_ID = a.TEST_COMPONENT_ID 
   AND a.LABORATORY = b.LABORATORY 
   AND a.MAP_VERSION = b.MAP_VERSION 
   AND a.OC_LAB_QUESTION IS NOT NULL 
GROUP BY n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY						

SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.load_flag, n.TEST_COMPONENT_ID, n.LABORATORY, error_reason FROM NCI_LABS n, NCI_CDW_LAB_MAP_CROSSREF a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND TO_CHAR(n.TEST_COMPONENT_ID) = TO_CHAR(a.TEST_ID) AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.load_flag, n.error_reason, n.TEST_COMPONENT_ID, n.LABORATORY UNION SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.load_flag, n.TEST_COMPONENT_ID, n.LABORATORY, error_reason FROM NCI_LABS n, NCI_LAB_MAPPING a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND n.TEST_COMPONENT_ID = a.TEST_COMPONENT_ID AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.load_flag, n.error_reason, n.TEST_COMPONENT_ID, n.LABORATORY

SELECT CARDINALITY "Rows",
       LPAD(' ',LEVEL-1)||operation||' '||
       options||' '||object_name "Plan"
  FROM PLAN_TABLE
CONNECT BY PRIOR ID = parent_id
        AND PRIOR STATEMENT_ID = STATEMENT_ID
  ORDER BY ID;

  
  SELECT COUNTER,OC_STUDY,LOAD_FLAG,LABORATORY,TEST_COMPONENT_ID,ERROR_REASON FROM (SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY FROM NCI_LABS n, NCI_CDW_LAB_MAP_CROSSREF a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND n.TEST_COMPONENT_ID = a.TEST_ID AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.load_flag, n.error_reason, n.TEST_COMPONENT_ID, n.LABORATORY UNION SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY FROM NCI_LABS n, NCI_LAB_MAPPING a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND n.TEST_COMPONENT_ID = a.TEST_COMPONENT_ID AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.load_flag, n.error_reason, n.TEST_COMPONENT_ID, n.LABORATORY)
  
  
CREATE OR REPLACE VIEW OPS$BDL.NCI_CDW_LAB_MAP_CROSSREF
(TEST_ID, EC_ID, OTH_TEST_ID, LABORATORY, OC_LAB_QUESTION, 
 MAP_VERSION)
AS 
SELECT TO_CHAR (a.test_id) test_id, a.ec_id ec_id, TO_CHAR(b.test_id) oth_test_id, 
       c.laboratory, c.oc_lab_question, c.map_version 
  FROM mis_cdr_tests a, 
       mis_cdr_tests b, 
	   NCI_LAB_MAPPING c 
 WHERE a.ec_id = b.ec_id 
   AND TO_CHAR(b.test_id) = c.test_component_id
   
   
   SELECT COUNTER,OC_STUDY,LOAD_FLAG,TEST_COMPONENT_ID FROM (SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY FROM NCI_LABS n, NCI_CDW_LAB_MAP_CROSSREF a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND n.TEST_COMPONENT_ID = a.TEST_ID AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY UNION SELECT /*+ hint index(n, NCI_LABS_ERR2) */ COUNT(*) Counter, n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY FROM NCI_LABS n, NCI_LAB_MAPPING a, NCI_LAB_LOAD_STUDY_CTLS_VW b WHERE n.load_flag = 'E' AND n.ERROR_REASON = 'Lab Test is unmapped' AND n.OC_STUDY = b.OC_STUDY AND n.LABORATORY = b.LABORATORY AND n.TEST_COMPONENT_ID = a.TEST_COMPONENT_ID AND a.LABORATORY = b.LABORATORY AND a.MAP_VERSION = b.MAP_VERSION AND a.OC_LAB_QUESTION IS NOT NULL GROUP BY n.OC_STUDY, n.TEST_COMPONENT_ID, n.LABORATORY)
   
    SELECT Lab_TEST --INTO :PROCESS_UNMAPPED_DETAIL.TEST_NAME
	 	     FROM NCI_LAB_MAPPING a
			 WHERE a.TEST_COMPONENT_ID = '1'
			 
			  DECLARE
			  x VARCHAR2(200);
			  BEGIN x := cdw_data_transfer_v3.FIND_LAB_QUESTION('1','1','1'); END;