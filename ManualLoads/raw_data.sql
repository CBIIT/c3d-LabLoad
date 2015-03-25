--
--SQL Statement which produced this data:
--  select oc_study, patient_id, NULL, substr(sample_datetime,1,2)||'/'||substr(sample_datetime,3,2)||'/2006' raw_date, 
--         substr(sample_datetime,7,2)||':'||substr(sample_datetime,9,2)||':00' raw_time, OC_LAB_QUESTION, RESULT, UNIT, Normal_Value, NULL, 
--  	   NULL, NULL, NULL 
--   from nci_labs 
--  where oc_study = '04_C_0121' 
--    and load_flag = 'C' 
--    and oc_patient_pos = '1' 
--    and sample_datetime = '0721041636' 
--    and oc_lab_event = 'BLOOD CHEMISTRY'
--
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'SGPT_ALT', '49', 'U/L', '6-41', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'SGOT_AST', '51', 'U/L', '9-34', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'ALBUMIN_SERUM', '3.8', 'g/dL', '3.7-4.7', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'ALK_PHOS', '102', 'U/L', '37-116', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'BILIRUBIN_DIRECT', '0.2', 'mg/dL', '0.0-0.2', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'BILIRUBIN_TOTAL', '0.8', 'mg/dL', '0.1-1.0', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'CALCIUM', '2.39', 'mmol/L', '2.05-2.50', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'BICARB_SERUM', '25', 'mmol/L', '21-31', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'CHLORIDE', '104', 'mmol/L', '99-107', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'CREATININE', '0.6', 'mg/dL', '0.7-1.3', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'GLUC_NONFASTING', '242', 'mg/dL', '70-115', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'LDH', '179', 'U/L', '113-226', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'MAGNESIUM', '0.90', 'mmol/L', '0.75-1.00', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'INORG_PHOS', '3.8', 'mg/dL', '2.5-4.8', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'POTASSIUM', '4.0', 'mmol/L', '3.3-5.1', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'TOT_PROT', '5.8', 'g/dL', '6.0-7.6', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'SODIUM', '136', 'mmol/L', '135-144', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'BUN', '11', 'mg/dL', '8-22', NULL, 
    NULL, NULL, NULL);
Insert into nci_labs_manual_load_Hold
   (OC_STUDY, PATIENT_ID, NULL, RAW_DATE, RAW_TIME, 
    OC_LAB_QUESTION, RESULT, UNIT, NORMAL_VALUE, NULL_1, 
    NULL_2, NULL_3, NULL_4)
 Values
   ('04_C_0121', '3148567', NULL, '07/21/2006', '16:36:00', 
    'URIC_ACID', '3.3', 'mg/dL', '2.4-5.8', NULL, 
    NULL, NULL, NULL);
COMMIT;
