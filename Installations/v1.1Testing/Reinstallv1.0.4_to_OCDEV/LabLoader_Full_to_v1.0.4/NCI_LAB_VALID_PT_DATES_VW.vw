CREATE OR REPLACE FORCE VIEW NCI_LAB_VALID_PT_DATES_VW
(PT_ID, PT, STUDY, NCI_INST_CD, OFFSTDY_DT_DCM, 
 OFFSTDY_DT_QST, OFFSTDY_DT_VALUE, PSTDY_DT_DCM, PSTDY_DT_QST, PSTDY_DT_VALUE, 
 USE_ENROLL, ENROLL_DT_DCM, ENROLL_DT_QST, ENROLL_DT_VALUE)
AS 
select a.*, 
	   nvl(b.OFF_STUDY_DCM,c.OFF_STUDY_DCM) OFFSTDY_DT_DCM, 
	   nvl(b.OFF_STUDY_QUEST,c.OFF_STUDY_QUEST) OFFSTDY_DT_QST, 
	   get_response_value(a.study,a.pt, nvl(b.OFF_STUDY_DCM,c.OFF_STUDY_DCM), 
						  nvl(b.OFF_STUDY_QUEST,c.OFF_STUDY_QUEST)) OFFSTDY_DT_VALUE, 
	   nvl(b.PRESTUDY_LAB_DATE_DCM,c.PRESTUDY_LAB_DATE_DCM) PSTDY_DT_DCM, 
	   nvl(b.PRESTUDY_LAB_DATE_QUEST,c.PRESTUDY_LAB_DATE_QUEST) PSTDY_DT_QST, 
	   get_response_value(a.study,a.pt, nvl(b.PRESTUDY_LAB_DATE_DCM,c.PRESTUDY_LAB_DATE_DCM), 
						  nvl(b.PRESTUDY_LAB_DATE_QUEST,c.PRESTUDY_LAB_DATE_QUEST))  PSTDY_DT_VALUE, 
	   nvl(b.BLANK_PRESTUDY_USE_ENROLL, c.BLANK_PRESTUDY_USE_ENROLL) USE_ENROLL, 
       nvl(b.ENROLLMENT_DATE_DCM,c.ENROLLMENT_DATE_DCM) ENROLL_DT_DCM, 
	   nvl(b.ENROLLMENT_DATE_QUEST,c.ENROLLMENT_DATE_QUEST) ENROLL_DT_QST, 
	   get_response_value(a.study,a.pt, nvl(b.ENROLLMENT_DATE_DCM,c.ENROLLMENT_DATE_DCM), 
                          nvl(b.ENROLLMENT_DATE_QUEST,c.ENROLLMENT_DATE_QUEST)) enroll_dt_value 
from NCI_LAB_VALID_PATIENTS_VW a, 
     nci_lab_load_ctl b, 
	 nci_lab_load_ctl c 
where a.study = b.oc_study 
  and c.oc_study = 'ALL' 
UNION 
select a.*, 
	   c.OFF_STUDY_DCM OFFSTDY_DT_DCM, 
	   c.OFF_STUDY_QUEST OFFSTDY_DT_QST, 
	   get_response_value(a.study, a.pt, c.OFF_STUDY_DCM, c.OFF_STUDY_QUEST) OFFSTDY_DT_VALUE, 
	   c.PRESTUDY_LAB_DATE_DCM PSTDY_DT_DCM, 
	   c.PRESTUDY_LAB_DATE_QUEST PSTDY_DT_QST, 
	   get_response_value(a.study, a.pt, c.PRESTUDY_LAB_DATE_DCM, c.PRESTUDY_LAB_DATE_QUEST) PSTDY_DT_VALUE, 
	   c.BLANK_PRESTUDY_USE_ENROLL USE_ENROLL, 
       c.ENROLLMENT_DATE_DCM ENROLL_DT_DCM, 
	   c.ENROLLMENT_DATE_QUEST ENROLL_DT_QST, 
	   get_response_value(a.study, a.pt, c.ENROLLMENT_DATE_DCM, c.ENROLLMENT_DATE_QUEST) enroll_dt_value 
from NCI_LAB_VALID_PATIENTS_VW a, 
	 nci_lab_load_ctl c 
where not exists (select 'X' from nci_lab_load_ctl 
                  where oc_study = a.study) 
  and c.oc_study = 'ALL';


