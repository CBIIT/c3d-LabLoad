--SCRIPT 1 
insert into gu_lab_results_stage 
      (MRN,             SHORT_NAME,          LONG_NAME,       
	   SAMPLE_DATE_RAW, SAMPLE_TIME_RAW,     RESULT,    
	   HI_LOW,          RANGE,               STUDY_NO,           
	   INITIALS,        DEPT,                UNITS_RAW,        
	   SAMPLE_DATETIME, 
	   PROCESS_DATE,    TEST_COMPONENT_ID,   C3DLABNAME,
	   GU_LAB_ID)
select MRN,             SHORT_NAME,          LONG_NAME, 
       SAMPLE_DATE_RAW, SAMPLE_TIME_RAW,     RESULT, 
	   HI_LOW,          RANGE,               STUDY_NO, 
	   INITIALS,        DEPT,                UNITS_RAW, 
	   to_date(sample_date_raw||' '||lpad(sample_time_raw,4,'0'),'DD-MON-RR HH24MI'), 
	   sysdate,         GU_LAB_ID,           C3D_LAB_NAME, 
	   GU_LAB_ID
  from gu_lab_results_hold; 

--  SCRIPT 2  
insert into NCI_LABS
                  (PATIENT_ID
                   ,CDW_RESULT_ID
                   ,SAMPLE_DATETIME
                   ,TEST_COMPONENT_ID
                   ,TEST_CODE
                   ,LABORATORY
                   ,LABTEST_NAME
                   ,RESULT
                   ,UNIT
                   ,NORMAL_VALUE
                   ,RECEIVED_DATE)
SELECT MRN PATIENT_ID
       ,RECORD_ID RESULT_ID
       ,to_char(SAMPLE_DATETIME,'MMDDYYHH24MI')  COLLECT_DATETIME
       ,TEST_COMPONENT_ID TEST_COMPONENT_ID 
       ,SHORT_NAME TEST_CODE
       ,'GEORGETOWN' LABORATORY
       ,SHORT_NAME TEST_NAME
       ,RESULT TEXT_RESULT
       ,UNITS_RAW TEST_UNIT
       ,RANGE RANGE
       ,SYSDATE
  FROM gu_lab_results_stage
 WHERE LOAD_FLAG = 'N';  

 -- SCRIPT 3 
Update gu_laB_results_stage
   set load_flag = 'C' where load_flag = 'N'; 
 
-- SCRIPT 4   
COmmit;
			 
-- script 5  not needed 
Rollback;