CREATE OR REPLACE FORCE VIEW OPS$BDL.NCI_LAB_VALID_PATIENTS_VW
(PT_ID, PT, STUDY, NCI_INST_CD)
AS 
SELECT REPLACE (pt_id_ful, '-') pt_id, oc_patient_pos pt, oc_study, 
          nci_inst_cd_ful nci_inst_cd 
     FROM nci_study_patient_ids a 
    WHERE pt_id_ful IS NOT NULL 
      AND (   (nci_inst_cd_ful LIKE '%NCI%' ) --or nci_inst_cd_ful IN ('GTOWN') ) 
           OR (    nci_inst_cd_ful = 'NIHCC' 
               AND oc_study IN ('97_C_0110', '99_C_0023', '00_C_0030') 
              ) 
		   OR exists (select 'x' from NCI_STUDY_PATIENT_IDS_CTL b 
		               where b.OC_STUDY = a.oc_study 
					     and b.NCI_INST_CD_CONST is not null 
						 and b.NCI_INST_CD_CONST = a.nci_inst_cd_ful) 
          ) 
      AND pt_id_ful NOT IN ( 
                SELECT   pt_id_ful 
                    FROM nci_study_patient_ids t 
                   WHERE pt_id_ful IS NOT NULL 
                     AND t.nci_inst_cd_ful LIKE '%NCI%' 
                GROUP BY t.pt_id_ful, t.oc_study,t.OC_PATIENT_POS
                  HAVING COUNT (*) > 1) 
      AND DECODE 
             (INSTR 
                 (TRANSLATE 
                     (pt_id_ful, 
                      './ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
                      'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' 
                     ), 
                  'X' 
                 ), 
              0, 'number', 
              'not_number' 
             ) = 'number';
