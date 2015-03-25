CREATE OR REPLACE FORCE VIEW CTDEV.STUDY_REPEAT_DEFAULTS_VW
(STUDY, BOOK, BOOK_STATUS, DCI, DCM, 
 SUBSET_NAME, QUESTION, REPEAT_SN, DEFAULT_VALUE_TEXT, GLIB_LAB)
AS 
select distinct 
  s.study 
, db.name book 
, db.dci_book_status_code book_status 
, i.name dci 
, d.name dcm 
, d.subset_name 
, dq.question_name question 
, r.repeat_sn 
, r.default_value_text 
, decode(dq.question_name,'LPARM',nvl(l.name,'Not Mapped')) glib_lab 
from dcms d 
, dcm_questions dq 
, dcm_ques_repeat_defaults r 
, clinical_studies s 
, dci_books db 
, dci_book_pages dbp 
, dci_modules dm 
, dcis i 
, labtests l 
where r.dcm_question_id=dq.dcm_question_id 
and r.dcm_subset_sn=dq.dcm_que_dcm_subset_sn 
and dq.dcm_id=d.dcm_id 
and dq.dcm_que_dcm_subset_sn=d.dcm_subset_sn 
and d.dcm_id=dm.dcm_id 
and d.dcm_subset_sn=dm.dcm_subset_sn 
and dm.dci_id=dbp.dci_id 
and dbp.dci_id=i.dci_id 
and db.dci_book_id=dbp.dci_book_id 
and db.dci_book_status_code <> 'R' 
and db.clinical_study_id=s.clinical_study_id 
and r.default_value_text=l.name(+) 
order by 1,2,4,5,6,7;


GRANT SELECT ON  CTDEV.STUDY_REPEAT_DEFAULTS_VW TO OC_STUDY_ROLE;

