UPDATE NCI_LAB_LOAD_CTL 
SET
BLANK_PRESTUDY_USE_ENROLL = 'Y'
WHERE OC_STUDY = 'LAB_LOADER';

commit;
 
