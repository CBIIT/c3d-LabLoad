CREATE OR REPLACE FORCE VIEW NCI_LAB_LOAD_STUDY_SEC_VW
(STUDY)
AS 
SELECT study
     FROM clinical_studies a
    WHERE EXISTS (SELECT 'X'
                    FROM nci_labs
                   WHERE oc_study = study)
      AND (   EXISTS
                     /* account is super-user   */
              (
                 SELECT /*+ INDEX(OA ORACLE_ACCOUNT_PK_IDX) */
                        NULL
                   FROM oracle_accounts oa
                  WHERE oa.oracle_account_name = USER
                    AND oa.all_study_access_flag = 'Y')
           OR EXISTS
                     /* account is in group with program/project access  */
                     /* rdanka- bug 902780 changed use_index to index */
              (
                 SELECT /*+ ORDERED
                     INDEX(AGM ACCOUNT_GRP_MEMB_PK_IDX)
                     INDEX(APA ACCOUNT_PROG_ACCESS_PK_IDX)
                     INDEX(S OCL_STUDY_UK_IDX) */
                        NULL
                   FROM account_group_memberships agm,
                        account_program_accesses apa,
                        ocl_studies s
                  WHERE agm.account_grp_memb_ora_oa_name = USER
                    AND agm.account_grp_memb_grp_oa_name =
                                               apa.account_prog_access_oa_name
                    AND s.program_code = apa.account_prog_access_prog_code
                    AND s.project_code LIKE apa.account_prog_access_proj_code
                    AND s.study = a.study /* prc */)
           OR EXISTS
                     /* account is in group with study access  */
                     /* rdanka- bug 902780 changed use_index to index */
              (
                 SELECT /*+ ORDERED
                     INDEX(AGM ACCOUNT_GRP_MEMB_PK_IDX)
                     INDEX(ASA ACCT_STUDY_ACC_PK_IDX) */
                        NULL
                   FROM account_group_memberships agm,
                        account_study_accesses asa,
                        ocl_studies s
                  WHERE agm.account_grp_memb_ora_oa_name = USER
                    AND agm.account_grp_memb_grp_oa_name =
                                              asa.account_study_access_oa_name
                    AND asa.account_study_access_cs_id = s.task_id   /* prc */
                    AND s.study = a.study /* prc */)
           OR EXISTS
                     /* account has direct program/project access  */
              (
                 SELECT /*+ ORDERED
                     INDEX(APA ACCOUNT_PROG_ACCESS_PK_IDX)
                     INDEX(S OCL_STUDY_UK_IDX) */
                        NULL
                   FROM account_program_accesses apa, ocl_studies s
                  WHERE apa.account_prog_access_oa_name = USER
                    AND s.program_code = apa.account_prog_access_prog_code
                    AND s.project_code LIKE apa.account_prog_access_proj_code
                    AND s.study = a.study /* prc */)
           OR EXISTS
                     /* account has direct study access  */
                     /* rdanka- bug 902780 changed use_index to index */
              (
                 SELECT /*+ INDEX(ASA ACCT_STUDY_ACC_PK_IDX) */
                        NULL
                   FROM account_study_accesses asa, ocl_studies s
                  WHERE asa.account_study_access_cs_id = s.task_id   /* prc */
                    AND s.study = a.study                            /* prc */
                    AND asa.account_study_access_oa_name = USER)
          );



