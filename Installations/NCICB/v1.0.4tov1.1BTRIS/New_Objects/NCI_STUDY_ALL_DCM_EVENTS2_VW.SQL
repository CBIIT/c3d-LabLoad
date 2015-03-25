CREATE OR REPLACE FORCE VIEW NCI_STUDY_ALL_DCM_EVENTS2_VW
(OC_STUDY, CLINICAL_STUDY_ID, DCM_NAME, SUBSET_NAME, QUESTION_NAME, 
 CPE_NAME, REPEAT_SN, OC_LAB_QUESTION, DISPLAY_SN)
AS 
SELECT cs.study oc_study,     cs.clinical_study_id, 
       d.NAME dcm_name,       d.subset_name, 
       dq.question_name,      cpe.NAME cpe_name, 
       r.repeat_sn,           r.default_value_text oc_lab_question, 
       dbp.display_sn 
  FROM dcms d, 
       dcm_questions dq, 
       dcm_ques_repeat_defaults r, 
       dci_modules dm, 
       clinical_planned_events cpe, 
       dci_book_pages dbp, 
       dci_books db, 
       clinical_studies cs, 
       clinical_study_versions csv 
 WHERE csv.clinical_study_id = cs.clinical_study_id 
   and cpe.CLIN_STUDY_ID = csv.CLINICAL_STUDY_ID 
   and cpe.CLIN_STUDY_VERSION_ID = csv.CLINICAL_STUDY_VERSION_ID 
   and db.CLINICAL_STUDY_ID = cs.CLINICAL_STUDY_ID 
   AND db.dci_book_status_code = 'A' 
   AND dbp.clin_plan_eve_id = cpe.clin_plan_eve_id 
   AND dbp.dci_book_id = db.dci_book_id 
   AND dbp.CLINICAL_STUDY_ID = csv.CLINICAL_STUDY_ID 
   AND dm.dci_id = dbp.dci_id 
   AND d.dcm_id = dm.dcm_id 
   AND d.dcm_subset_sn = dm.dcm_subset_sn 
   AND d.dcm_layout_sn = dm.dcm_layout_sn 
   AND d.dcm_id = dq.dcm_id 
   AND d.dcm_subset_sn = dq.dcm_que_dcm_subset_sn 
   AND d.dcm_layout_sn = dq.dcm_que_dcm_layout_sn 
   and r.dcm_question_id (+) = dq.dcm_question_id 
   AND r.dcm_subset_sn (+) = dq.dcm_que_dcm_subset_sn 
   AND r.dcm_layout_sn (+) = dq.dcm_que_dcm_layout_sn
/


