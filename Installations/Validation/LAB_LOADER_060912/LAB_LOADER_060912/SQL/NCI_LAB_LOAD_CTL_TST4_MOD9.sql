UPDATE NCI_LAB_LOAD_CTL 
SET
REVIEW_STUDY = 'Y',
LOAD_OTHER_LABS = 'Y'
WHERE OC_STUDY = 'LAB_LOADER';

commit;
 