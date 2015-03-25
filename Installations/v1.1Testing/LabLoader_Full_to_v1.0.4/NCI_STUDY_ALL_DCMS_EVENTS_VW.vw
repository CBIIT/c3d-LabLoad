/* Formatted on 2005/12/09 15:34 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW nci_study_all_dcms_events_vw (oc_study,
                                                                   dcm_name,
                                                                   subset_name,
                                                                   question_name,
                                                                   cpe_name,
                                                                   repeat_sn,
                                                                   oc_lab_question,
                                                                   display_sn
                                                                  )
AS
   SELECT DISTINCT dm.clinical_study_id oc_study, d.NAME dcm_name,
                   d.subset_name, dq.question_name, cpe.NAME cpe_name,
                   r.repeat_sn, r.default_value_text oc_lab_question,
                   dbp.display_sn
              FROM dcms d,
                   dcm_questions dq,
                   dcm_ques_repeat_defaults r,
                   dci_modules dm,
                   clinical_planned_events cpe,
                   dci_book_pages dbp,
                   dci_books db
             WHERE dq.dcm_question_id = r.dcm_question_id(+)
               AND dq.dcm_que_dcm_subset_sn = r.dcm_subset_sn(+)
               AND d.dcm_id = dq.dcm_id
               AND d.dcm_subset_sn = dq.dcm_que_dcm_subset_sn
               AND d.dcm_layout_sn = dq.dcm_que_dcm_layout_sn
               AND dm.dcm_id = d.dcm_id
               AND dm.dcm_subset_sn = d.dcm_subset_sn
               AND dm.dcm_layout_sn = d.dcm_layout_sn
               AND dbp.dci_id = dm.dci_id
               AND dbp.clin_plan_eve_id = cpe.clin_plan_eve_id
               AND db.dci_book_id = dbp.dci_book_id
               AND db.dci_book_status_code = 'A'
               AND db.default_flag = 'Y';


