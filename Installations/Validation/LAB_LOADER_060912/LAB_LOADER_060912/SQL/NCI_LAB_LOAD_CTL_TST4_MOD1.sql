UPDATE NCI_LAB_LOAD_CTL 
SET
STOP_LAB_LOAD_FLAG = 'Y',
LOAD_OTHER_LABS = NULL,
LABTESTNAME_IS_OCLABQUEST = NULL
WHERE OC_STUDY = 'LAB_LOADER';

UPDATE NCI_LAB_LOAD_CTL 
SET
LABTESTNAME_IS_OCLABQUEST = 'N'
WHERE OC_STUDY = 'ALL';

commit;
 
