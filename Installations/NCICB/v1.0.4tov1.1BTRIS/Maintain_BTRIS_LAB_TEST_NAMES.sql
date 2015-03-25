-- Script for Creating BTRIS Lab Tests and performing the mappings.

-- Create the basic from the Lab Results previously gathered.

/*CREATE TABLE BTRIS_LAB_TEST_NAMES AS
SELECT BTRIS_LAB_TEST_ID, 
       LAB_TEST_NAME, 
	   LABTEST_CODE, 
	   LAB_UNIT, 
	   LAB_RANGE, 
	   MIN(LAB_REPORT_DATE) FIRST_REPORT_DATE, 
	   MAX(LAB_REPORT_DATE) LAST_REPORT_DATE
  FROM BTRIS_LAB_RESULTS A
  GROUP BY BTRIS_LAB_TEST_ID, LAB_TEST_NAME, LABTEST_CODE, LAB_UNIT, LAB_RANGE 
*/
--Insert NEW Lab Test Name records that do not already exists
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
                       
-- Update the First and Last Dates
UPDATE BTRIS_LAB_TEST_NAMES A
   SET (FIRST_REPORT_DATE, LAST_REPORT_DATE) = 
        (SELECT MIN(LAB_REPORT_DATE) FIRST_REPORT_DATE, 
                MAX(LAB_REPORT_DATE) LAST_REPORT_DATE
           FROM BTRIS_LAB_RESULTS B
		   WHERE B.BTRIS_LAB_TEST_ID = A.BTRIS_LAB_TEST_ID  
             AND B.LAB_TEST_NAME = A.LAB_TEST_NAME 
             AND B.LABTEST_CODE = A.LABTEST_CODE 
             AND NVL(B.LAB_UNIT,'~') = NVL(A.LAB_UNIT,'~') 
             AND NVL(B.LAB_RANGE,'~') = NVL(A.LAB_RANGE,'~')
           GROUP BY BTRIS_LAB_TEST_ID, LAB_TEST_NAME, LABTEST_CODE, LAB_UNIT, LAB_RANGE);                       
                       
                       