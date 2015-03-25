/* Formatted on 2005/12/09 15:32 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW c3d_accessible_studies_vw (study, title)
AS
   SELECT a.study, a.title
     FROM ocl_studies a
    WHERE EXISTS (                               /* account is super-user   */
             SELECT /*+ INDEX(OA ORACLE_ACCOUNT_PK_IDX) */
                    NULL
               FROM oracle_accounts oa
              WHERE oa.oracle_account_name = USER
                AND oa.all_study_access_flag = 'Y')
       OR EXISTS (      /* account is in group with program/project access  */
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
       OR EXISTS (                /* account is in group with study access  */
             SELECT /*+ ORDERED 
                 INDEX(AGM ACCOUNT_GRP_MEMB_PK_IDX) 
                 INDEX(ASA ACCT_STUDY_ACC_PK_IDX) */
                    NULL
               FROM account_group_memberships agm, account_study_accesses asa
              WHERE agm.account_grp_memb_ora_oa_name = USER
                AND agm.account_grp_memb_grp_oa_name =
                                              asa.account_study_access_oa_name
                AND asa.account_study_access_cs_id = a.task_id)
       OR EXISTS (            /* account has direct program/project access  */
             SELECT /*+ ORDERED 
                 INDEX(APA ACCOUNT_PROG_ACCESS_PK_IDX) 
                 INDEX(S OCL_STUDY_UK_IDX) */
                    NULL
               FROM account_program_accesses apa, ocl_studies s
              WHERE apa.account_prog_access_oa_name = USER
                AND s.program_code = apa.account_prog_access_prog_code
                AND s.project_code LIKE apa.account_prog_access_proj_code
                AND s.study = a.study /* prc */)
       OR EXISTS (                      /* account has direct study access  */
             SELECT /*+ INDEX(ASA ACCT_STUDY_ACC_PK_IDX) */
                    NULL
               FROM account_study_accesses asa
              WHERE asa.account_study_access_cs_id = a.task_id       /* prc */
                AND asa.account_study_access_oa_name = USER);




