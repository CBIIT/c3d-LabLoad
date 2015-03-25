
CREATE OR REPLACE FORCE VIEW NCI_LAB_DUP_PATIENTS_VW
(PT_ID, PT, OC_STUDY, NCI_INST_CD)
AS 
SELECT REPLACE (pt_id_ful, '-') pt_id, oc_patient_pos pt, oc_study, 
          nci_inst_cd_ful nci_inst_cd 
     FROM nci_study_patient_ids a 
    WHERE exists ( 
                SELECT   pt_id_ful 
                    FROM nci_study_patient_ids t 
                   WHERE t.oc_study = a.oc_study 
	                 and replace(t.pt_id_ful,'-') = replace(a.pt_id_ful,'-') 
                GROUP BY replace(t.pt_id_ful,'-') 
                  HAVING COUNT (*) > 1);

CREATE PUBLIC SYNONYM NCI_LAB_DUP_PATIENTS_VW FOR NCI_LAB_DUP_PATIENTS_VW;

GRANT SELECT ON  NCI_LAB_DUP_PATIENTS_VW TO LABLOADER;

GRANT SELECT ON  NCI_LAB_DUP_PATIENTS_VW TO LABLOADER_ADMIN;

GRANT SELECT ON  NCI_LAB_DUP_PATIENTS_VW TO LABLOADER_REVIEW;

