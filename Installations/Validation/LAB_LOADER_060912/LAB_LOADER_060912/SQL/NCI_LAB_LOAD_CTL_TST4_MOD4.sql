UPDATE NCI_LAB_LOAD_CTL 
SET
DATE_CHECK_CODE = 'PRE'
WHERE OC_STUDY = 'LAB_LOADER';

commit;
 
