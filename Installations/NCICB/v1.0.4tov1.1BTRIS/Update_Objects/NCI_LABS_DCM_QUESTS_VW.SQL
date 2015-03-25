CREATE OR REPLACE FORCE VIEW NCI_LABS_DCM_QUESTS_VW
(RECORD_ID, OC_STUDY, OC_LAB_PANEL, OC_LAB_SUBSET, OC_LAB_EVENT, 
 OC_PATIENT_POS, LOAD_FLAG, OC_LAB_QUESTION, RESULT, UNIT, 
 SAMPLE_DATETIME, REPEAT_SN)
AS 
select a.RECORD_ID, b.study oc_study, b.DCM_NAME oc_lab_panel,
       b.SUBSET_NAME oc_lab_subset, b.cpe_name oc_lab_event, a.oc_patient_pos,
       a.load_flag, b.oc_lab_question, a.result, a.unit,
       a.sample_datetime, b.REPEAT_SN
  from nci_labs a,
       NCI_STUDY_LABDCM_EVENTS_TB b
 Where a.oc_study         (+)= b.STUDY
   and a.OC_LAB_PANEL     (+)= b.DCM_NAME
   and a.OC_LAB_SUBSET    (+)= b.SUBSET_NAME
   and a.oc_lab_question  (+)= b.oc_lab_question
   and a.oc_lab_event     (+)= b.CPE_NAME
/


