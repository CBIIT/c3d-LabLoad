create or replace view nci_study_dcms_vw as
select distinct
	DM.CLINICAL_STUDY_ID OC_STUDY,
	D.NAME DCM_NAME,
	d.subset_name,
	DQ.QUESTION_NAME,
	CPE.NAME CPE_NAME,
	R.REPEAT_SN,
	R.DEFAULT_VALUE_TEXT OC_LAB_QUESTION
from dcms d
, dcm_questions dq
, dcm_ques_repeat_defaults r
, dci_modules dm
, clinical_planned_events cpe
, dci_book_pages dbp
, dci_books db
where dq.dcm_question_id=r.dcm_question_id
and dq.dcm_que_dcm_subset_sn=r.dcm_subset_sn
and d.dcm_id=dq.dcm_id
and d.dcm_subset_sn=dq.dcm_que_dcm_subset_sn
and dm.dcm_id=d.dcm_id
and dm.dcm_subset_sn=d.dcm_subset_sn
and dbp.dci_id=dm.dci_id
and dbp.clin_plan_eve_id=cpe.clin_plan_eve_id
and db.dci_book_id=dbp.dci_book_id
and db.dci_book_status_code='A'
/