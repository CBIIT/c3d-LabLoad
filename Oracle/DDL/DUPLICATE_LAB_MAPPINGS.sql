CREATE OR REPLACE FORCE VIEW CTDEV.DUPLICATE_LAB_MAPPINGS
(STUDY, DCI, DCM, SUBSET_NAME, REPEAT_SN, 
 DEFAULT_VALUE_TEXT)
AS 
select distinct sr.study,sr.dci,sr.dcm,sr.subset_name,sr.repeat_sn,sr.default_value_text 
from STUDY_REPEAT_DEFAULTS_VW sr 
,(select study,book,default_value_text,count(*) 
  from STUDY_REPEAT_DEFAULTS_VW 
  where question='LPARM' 
  group by study,book,default_value_text 
  having count(*)>1) dup 
where dup.study=sr.study 
and dup.default_value_text=sr.default_value_text 
order by 1,6,2,3,4;


GRANT SELECT ON  CTDEV.DUPLICATE_LAB_MAPPINGS TO OC_STUDY_ROLE;

