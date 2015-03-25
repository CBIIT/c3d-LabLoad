/* Formatted on 2005/12/13 16:34 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW nci_labs_rev_sppdq_vw (oc_study,
                                                            patient_id,
                                                            oc_patient_pos,
                                                            oc_lab_panel,
                                                            oc_lab_event,
                                                            oc_lab_subset,
                                                            sample_datetime,
                                                            dci_name,
                                                            oc_lab_question
                                                           )
AS
   SELECT /*+ RULE */
          oc_study, patient_id, oc_patient_pos, oc_lab_panel, oc_lab_event,
          oc_lab_subset, sample_datetime, dc.NAME dci_name, oc_lab_question
     FROM dci_modules dm, dcms d, dcis dc, nci_labs n
    WHERE d.dcm_id = dm.dcm_id
      AND d.dcm_subset_sn = dm.dcm_subset_sn
      AND d.dcm_layout_sn = dm.dcm_layout_sn
      AND dc.dci_id = dm.dci_id
      AND dc.dci_status_code = 'A'
      AND d.NAME = n.oc_lab_panel
      AND d.domain = n.oc_study
      AND d.subset_name = n.oc_lab_subset
      AND load_flag = 'R';


-- GRANT SELECT ON NCI_LABS_REV_SPPDQ_VW TO LABLOADER;

-- GRANT SELECT ON NCI_LABS_REV_SPPDQ_VW TO LABLOADER_REVIEW;

-- GRANT SELECT ON NCI_LABS_REV_SPPDQ_VW TO LABLOADER_ADMIN;

