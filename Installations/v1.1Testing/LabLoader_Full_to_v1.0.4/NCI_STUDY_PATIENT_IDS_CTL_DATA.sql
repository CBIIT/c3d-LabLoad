INSERT INTO NCI_STUDY_PATIENT_IDS_CTL 
       ( OC_STUDY, PATIENT_ID_DCM_NAME, PATIENT_ID_QUEST_NAME,
         NCI_INST_CD_DCM_NAME, NCI_INST_CD_QUEST_NAME, NCI_INST_CD_CONST, 
         CREATE_DATE, CREATE_USER, MODIFY_DATE, MODIFY_USER ) 
VALUES ( 'ALL', 'PATIENT_ID', 'PT_ID', 
         'PATIENT_ID', 'NCI_INST_CD', NULL,  SYSDATE, USER, NULL, NULL); 

COMMIT;
