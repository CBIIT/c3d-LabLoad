CREATE OR REPLACE FORCE VIEW NCI_LAB_LOAD_STUDY_CTLS_VW
(OC_STUDY, STOP_LAB_LOAD_FLAG, LABORATORY, LOAD_OTHER_LABS, REVIEW_STUDY, 
 LABTESTNAME_IS_OCLABQUEST, FIND_EVENT, DATE_CHECK_CODE, OFF_STUDY_DCM, OFF_STUDY_QUEST, 
 OFF_STUDY_OFFSET_DAYS, PRESTUDY_LAB_DATE_DCM, PRESTUDY_LAB_DATE_QUEST, PRESTUDY_OFFSET_DAYS, BLANK_PRESTUDY_USE_ENROLL, 
 ENROLLMENT_DATE_DCM, ENROLLMENT_DATE_QUEST, MAP_VERSION, ALLOW_MULT_PATIENTS, USE_QUALIFY_VALUE, 
 BASED_ON_STUDY, CLINICAL_STUDY_ID)
AS 
SELECT a.oc_study,
       NVL (TRIM (a.stop_lab_load_flag), b.stop_lab_load_flag) stop_lab_load_flag,
       NVL (TRIM (a.laboratory), b.laboratory) laboratory,
       NVL (TRIM (a.load_other_labs), b.load_other_labs) load_other_labs,
       NVL (TRIM (a.review_study), b.review_study) review_study,
       NVL (TRIM (a.labtestname_is_oclabquest), b.labtestname_is_oclabquest) labtestname_is_oclabquest,
       NVL (TRIM (a.find_event), nvl(b.find_event,'Y')) find_event,
       NVL (TRIM (a.date_check_code), b.date_check_code) date_check_code,
       NVL (TRIM (a.off_study_dcm), b.off_study_dcm) off_study_dcm,
       NVL (TRIM (a.off_study_quest), b.off_study_quest) off_study_quest,
       NVL (a.off_study_offset_days, b.off_study_offset_days) off_study_offset_days,
       NVL (TRIM (a.prestudy_lab_date_dcm), b.prestudy_lab_date_dcm) prestudy_lab_date_dcm,
       NVL (TRIM (a.prestudy_lab_date_quest), b.prestudy_lab_date_quest) prestudy_lab_date_quest,
       NVL (a.prestudy_offset_days, b.prestudy_offset_days) prestudy_offset_days,
       NVL (TRIM (a.blank_prestudy_use_enroll), b.blank_prestudy_use_enroll) blank_prestudy_use_enroll,
       NVL (TRIM (a.enrollment_date_dcm), b.enrollment_date_dcm) enrollment_date_dcm,
       NVL (TRIM (a.enrollment_date_quest), b.enrollment_date_quest) enrollment_date_quest,
       NVL (TRIM (a.map_version), b.map_version) map_version,
       NVL (TRIM (a.allow_mult_patients), b.allow_mult_patients) allow_mult_patients,
       NVL (TRIM (a.use_qualify_value), b.use_qualify_value) use_qualify_value,
       a.oc_study based_on_study,
       c.clinical_study_id
  FROM clinical_studies c,
       nci_lab_load_ctl a,
       nci_lab_load_ctl b
 WHERE c.study = a.oc_study
   AND b.oc_study = 'ALL'
UNION
SELECT c.study,
       a.stop_lab_load_flag stop_lab_load_flag,
       a.laboratory laboratory,
       a.load_other_labs load_other_labs,
       a.review_study review_study,
       a.labtestname_is_oclabquest labtestname_is_oclabquest,
       a.find_event find_event,
       a.date_check_code date_check_code,
       a.off_study_dcm off_study_dcm,
       a.off_study_quest off_study_quest,
       a.off_study_offset_days off_study_offset_days,
       a.prestudy_lab_date_dcm prestudy_lab_date_dcm,
       a.prestudy_lab_date_quest prestudy_lab_date_quest,
       a.prestudy_offset_days prestudy_offset_days,
       a.blank_prestudy_use_enroll blank_prestudy_use_enroll,
       a.enrollment_date_dcm enrollment_date_dcm,
       a.enrollment_date_quest enrollment_date_quest,
       a.map_version,
       a.allow_mult_patients,
       a.use_qualify_value,
       a.oc_study based_on_study,
       c.clinical_study_id
  FROM clinical_studies c, nci_lab_load_ctl a
 WHERE a.oc_study = 'ALL'
   AND NOT EXISTS (SELECT 'X'
                     FROM nci_lab_load_ctl b
                    WHERE b.oc_study = c.study AND b.oc_study <> 'ALL')
/

