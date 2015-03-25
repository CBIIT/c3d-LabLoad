/* Formatted on 2005/12/09 15:27 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW study_repeat_defaults_vw (study,
                                                             book,
                                                             book_status,
                                                             dci,
                                                             dcm,
                                                             subset_name,
                                                             question,
                                                             repeat_sn,
                                                             default_value_text,
                                                             glib_lab
                                                            )
AS
   SELECT DISTINCT s.study, db.NAME book, db.dci_book_status_code book_status,
                   i.NAME dci, d.NAME dcm, d.subset_name,
                   dq.question_name question, r.repeat_sn,
                   r.default_value_text,
                   DECODE (dq.question_name,
                           'LPARM', NVL (l.NAME, 'Not Mapped')
                          ) glib_lab
              FROM dcms d,
                   dcm_questions dq,
                   dcm_ques_repeat_defaults r,
                   clinical_studies s,
                   dci_books db,
                   dci_book_pages dbp,
                   dci_modules dm,
                   dcis i,
                   labtests l
             WHERE r.dcm_question_id = dq.dcm_question_id
               AND r.dcm_subset_sn = dq.dcm_que_dcm_subset_sn
               AND dq.dcm_id = d.dcm_id
               AND dq.dcm_que_dcm_subset_sn = d.dcm_subset_sn
               AND d.dcm_id = dm.dcm_id
               AND d.dcm_subset_sn = dm.dcm_subset_sn
               AND dm.dci_id = dbp.dci_id
               AND dbp.dci_id = i.dci_id
               AND db.dci_book_id = dbp.dci_book_id
               AND db.dci_book_status_code <> 'R'
               AND db.clinical_study_id = s.clinical_study_id
               AND r.default_value_text = l.NAME(+)
               AND EXISTS (SELECT NULL
                             FROM c3d_accessible_studies_vw k
                            WHERE s.study = k.study)
          ORDER BY 1, 2, 4, 5, 6, 7;
